import AppKit
import Foundation
import OpenPortsCore
import UserNotifications

@MainActor
final class AppUpdateService: ObservableObject {
    enum Status: Equatable {
        case idle
        case checking
        case upToDate(current: String)
        case updateAvailable(current: String, latest: String)
        case installing(version: String)
        case installSucceeded(version: String)
        case failed(message: String)
    }

    static let shared = AppUpdateService()

    @Published private(set) var status: Status = .idle
    @Published private(set) var latestVersion: String?
    @Published private(set) var releaseURL: URL?
    @Published private(set) var lastCheckedAt: Date?

    var statusMessage: String {
        switch status {
        case .idle:
            "Checks GitHub Releases for newer versions."
        case .checking:
            "Checking for updates..."
        case let .upToDate(current):
            "You are up to date (\(current))."
        case let .updateAvailable(current, latest):
            "Update available: \(latest) (current: \(current))."
        case let .installing(version):
            "Installing \(version) via Homebrew..."
        case let .installSucceeded(version):
            "Installed \(version). Restart OpenPorts to use the new version."
        case let .failed(message):
            "Update error: \(message)"
        }
    }

    var lastCheckedMessage: String {
        guard let lastCheckedAt else {
            return "Last checked: never"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Last checked \(formatter.localizedString(for: lastCheckedAt, relativeTo: Date()))"
    }

    var hasUpdateAvailable: Bool {
        if case .updateAvailable = status {
            return true
        }
        return false
    }

    var isBusy: Bool {
        switch status {
        case .checking, .installing:
            true
        default:
            false
        }
    }

    private let userDefaults: UserDefaults
    private let session: URLSession
    private let notificationCenter: UNUserNotificationCenter
    private let updateCheckInterval: TimeInterval

    init(
        userDefaults: UserDefaults = .standard,
        session: URLSession = .shared,
        notificationCenter: UNUserNotificationCenter = .current(),
        updateCheckInterval: TimeInterval = 24 * 60 * 60,
    ) {
        self.userDefaults = userDefaults
        self.session = session
        self.notificationCenter = notificationCenter
        self.updateCheckInterval = updateCheckInterval

        let lastCheckTimestamp = userDefaults.double(forKey: AppSettingsKey.lastUpdateCheckTimestamp)
        if lastCheckTimestamp > 0 {
            lastCheckedAt = Date(timeIntervalSince1970: lastCheckTimestamp)
        }
    }

    func performLaunchCheckIfNeeded() async {
        guard userDefaults.bool(forKey: AppSettingsKey.autoCheckForUpdates) else {
            AppLogger.shared.log("Automatic update checks are disabled")
            return
        }

        let now = Date()
        let lastCheckTimestamp = userDefaults.double(forKey: AppSettingsKey.lastUpdateCheckTimestamp)
        if lastCheckTimestamp > 0 {
            let elapsed = now.timeIntervalSince1970 - lastCheckTimestamp
            if elapsed < updateCheckInterval {
                AppLogger.shared.log("Skipping update check (checked recently)")
                return
            }
        }

        await checkForUpdates(manual: false)
    }

    func checkForUpdates(manual: Bool = true) async {
        guard !isBusy else {
            return
        }

        status = .checking

        do {
            let latestRelease = try await fetchLatestRelease()
            let currentVersion = currentAppVersion()
            let latestVersion = latestRelease.normalizedVersion

            self.latestVersion = latestVersion
            releaseURL = latestRelease.htmlURL

            let now = Date()
            lastCheckedAt = now
            userDefaults.set(now.timeIntervalSince1970, forKey: AppSettingsKey.lastUpdateCheckTimestamp)

            let hasUpdate = isNewerVersion(latestVersion, than: currentVersion)
            if hasUpdate {
                status = .updateAvailable(current: currentVersion, latest: latestVersion)
                AppLogger.shared.log("Update available: \(latestVersion) (current: \(currentVersion))")

                if !manual {
                    await postUpdateAvailableNotificationIfNeeded(version: latestVersion, releaseURL: latestRelease.htmlURL)
                }
            } else {
                status = .upToDate(current: currentVersion)
                AppLogger.shared.log("Already up to date (\(currentVersion))")
            }
        } catch {
            let message = Self.compactErrorMessage(from: error)
            status = .failed(message: message)
            AppLogger.shared.error("Update check failed: \(message)")
        }
    }

    func installUpdateViaHomebrew() async {
        let versionTarget = latestVersion ?? "latest"

        guard !isBusy else {
            return
        }

        status = .installing(version: versionTarget)

        do {
            let brewPath = try Self.findBrewPath()
            _ = try await Self.runCommand(executablePath: brewPath, arguments: ["update"])
            _ = try await Self.runCommand(
                executablePath: brewPath,
                arguments: ["upgrade", "--cask", "mohamedmohana/tap/openports"],
            )

            status = .installSucceeded(version: versionTarget)
            userDefaults.set(versionTarget, forKey: AppSettingsKey.lastNotifiedUpdateVersion)
            AppLogger.shared.log("Update installed via Homebrew: \(versionTarget)")
            await postInstallNotification(version: versionTarget)
        } catch {
            let message = Self.compactErrorMessage(from: error)
            status = .failed(message: message)
            AppLogger.shared.error("Homebrew update failed: \(message)")
        }
    }

    func openReleasePage() {
        if let releaseURL {
            NSWorkspace.shared.open(releaseURL)
            return
        }

        if let fallbackURL = URL(string: "https://github.com/MohamedMohana/openports/releases/latest") {
            NSWorkspace.shared.open(fallbackURL)
        }
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        guard let url = URL(string: "https://api.github.com/repos/MohamedMohana/openports/releases/latest") else {
            throw AppUpdateError.invalidReleaseURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("OpenPorts/\(currentAppVersion())", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppUpdateError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw AppUpdateError.badStatusCode(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(GitHubRelease.self, from: data)
    }

    private func currentAppVersion() -> String {
        if let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return bundleVersion
        }
        return OpenPortsCore.version
    }

    private func isNewerVersion(_ candidate: String, than current: String) -> Bool {
        if let candidateVersion = SemanticVersion(candidate), let currentVersion = SemanticVersion(current) {
            return candidateVersion > currentVersion
        }
        return candidate != current
    }

    private func postUpdateAvailableNotificationIfNeeded(version: String, releaseURL: URL) async {
        let lastNotifiedVersion = userDefaults.string(forKey: AppSettingsKey.lastNotifiedUpdateVersion) ?? ""
        guard lastNotifiedVersion != version else {
            return
        }

        guard await isNotificationAllowed() else {
            AppLogger.shared.log("Update available but notifications are not allowed")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "OpenPorts update available"
        content.body = "Version \(version) is available. Open Preferences to install."
        content.sound = .default
        content.userInfo = ["releaseURL": releaseURL.absoluteString]

        let request = UNNotificationRequest(
            identifier: "openports-update-\(version)",
            content: content,
            trigger: nil,
        )

        do {
            try await addNotificationRequest(request)
            userDefaults.set(version, forKey: AppSettingsKey.lastNotifiedUpdateVersion)
            AppLogger.shared.log("Posted update notification for version \(version)")
        } catch {
            let message = Self.compactErrorMessage(from: error)
            AppLogger.shared.error("Failed to post update notification: \(message)")
        }
    }

    private func postInstallNotification(version: String) async {
        guard await isNotificationAllowed() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "OpenPorts updated"
        content.body = "Version \(version) installed. Quit and reopen OpenPorts to finish."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "openports-update-installed-\(version)",
            content: content,
            trigger: nil,
        )

        do {
            try await addNotificationRequest(request)
        } catch {
            let message = Self.compactErrorMessage(from: error)
            AppLogger.shared.error("Failed to post install notification: \(message)")
        }
    }

    private func isNotificationAllowed() async -> Bool {
        await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    continuation.resume(returning: true)
                case .notDetermined:
                    Task {
                        let granted = await self.requestNotificationAuthorization()
                        continuation.resume(returning: granted)
                    }
                case .denied:
                    continuation.resume(returning: false)
                @unknown default:
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func requestNotificationAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private func addNotificationRequest(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            notificationCenter.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }

    private static func findBrewPath() throws -> String {
        let fileManager = FileManager.default
        let candidates = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
        ]

        for candidate in candidates where fileManager.isExecutableFile(atPath: candidate) {
            return candidate
        }

        throw AppUpdateError.brewNotFound
    }

    private static func runCommand(executablePath: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = arguments

                let outputPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = outputPipe

                do {
                    try process.run()
                    process.waitUntilExit()

                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(bytes: outputData, encoding: .utf8) ?? ""

                    guard process.terminationStatus == 0 else {
                        throw AppUpdateError.brewCommandFailed(output.isEmpty ? "unknown Homebrew error" : output)
                    }

                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func compactErrorMessage(from error: Error) -> String {
        let rawMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        return rawMessage.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
