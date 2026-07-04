import AppKit
import Combine
import Foundation
import OpenPortsCore

@MainActor
class MenuViewModel: ObservableObject {
    @Published private(set) var ports: [PortInfo] = []
    @Published private(set) var isLoading: Bool = false {
        didSet {
            if oldValue != isLoading {
                updateMenu()
            }
        }
    }

    @Published private(set) var lastError: String?
    @Published private(set) var lastUpdatedAt: Date?
    @Published var searchText: String = "" {
        didSet {
            if oldValue != searchText {
                updateMenu()
            }
        }
    }

    private struct ObservedSettings: Equatable {
        let refreshInterval: Double
        let showSystemProcesses: Bool
        let showUDPPorts: Bool
        let groupByCategory: Bool
        let groupByProcess: Bool
        let groupByApp: Bool
    }

    private let portScanner: PortScanner
    private let processResolver: ProcessResolver
    private let processManager: ProcessManager
    private let portExporter: PortExporter
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: AnyCancellable?
    private var previousPorts: [PortInfo] = []

    private let userDefaults = UserDefaults.standard
    private var refreshInterval: Double {
        userDefaults.double(forKey: AppSettingsKey.refreshInterval)
    }

    private var showSystemProcesses: Bool {
        userDefaults.bool(forKey: AppSettingsKey.showSystemProcesses)
    }

    private var showUDPPorts: Bool {
        userDefaults.bool(forKey: AppSettingsKey.showUDPPorts)
    }

    private var groupByCategory: Bool {
        userDefaults.bool(forKey: AppSettingsKey.groupByCategory)
    }

    private var groupByProcess: Bool {
        userDefaults.bool(forKey: AppSettingsKey.groupByProcess)
    }

    private var groupByApp: Bool {
        userDefaults.bool(forKey: AppSettingsKey.groupPorts)
    }

    private let menuAffectingPreferenceKeys: Set<String> = [
        AppSettingsKey.groupPorts,
        AppSettingsKey.showSystemProcesses,
        AppSettingsKey.groupByCategory,
        AppSettingsKey.groupByProcess,
    ]

    private var observedSettings = ObservedSettings(
        refreshInterval: AppSettings.defaultRefreshInterval,
        showSystemProcesses: AppSettings.defaultShowSystemProcesses,
        showUDPPorts: AppSettings.defaultShowUDPPorts,
        groupByCategory: AppSettings.defaultGroupByCategory,
        groupByProcess: AppSettings.defaultGroupByProcess,
        groupByApp: AppSettings.defaultGroupPorts,
    )

    var statusItemController: StatusItemController?

    init(
        portScanner: PortScanner,
        processResolver: ProcessResolver,
        processManager: ProcessManager,
    ) {
        self.portScanner = portScanner
        self.processResolver = processResolver
        self.processManager = processManager
        portExporter = PortExporter()
        AppSettings.registerDefaults(userDefaults: userDefaults)
        observedSettings = currentObservedSettings()

        setupNotifications()
        configureRefreshTimer()
        AppLogger.shared.log("MenuViewModel initialized")
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .refreshPorts)
            .sink { [weak self] _ in
                self?.refreshPorts()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .terminatePort)
            .sink { [weak self] notification in
                if let pid = notification.object as? Int {
                    Task {
                        await self?.terminateProcess(pid: pid, signal: .term)
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .forceKill)
            .sink { [weak self] notification in
                if let pid = notification.object as? Int {
                    Task {
                        await self?.terminateProcess(pid: pid, signal: .kill)
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .preferenceChanged)
            .sink { [weak self] notification in
                if let key = notification.object as? String {
                    AppLogger.shared.log("Preference changed via notification: \(key)")
                    self?.handlePreferenceChange(for: key)
                }
            }
            .store(in: &cancellables)

        observeUserDefaultsChanges()
    }

    private func observeUserDefaultsChanges() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: userDefaults)
            .sink { [weak self] notification in
                guard notification.object is UserDefaults else { return }
                self?.handleObservedDefaultsChange()
            }
            .store(in: &cancellables)
    }

    private func handlePreferenceChange(for key: String) {
        guard AppSettingsKey.trackedPreferenceKeys.contains(key) else {
            return
        }

        let previousSettings = observedSettings
        observedSettings = currentObservedSettings()

        if observedSettings.refreshInterval != previousSettings.refreshInterval {
            configureRefreshTimer()
        }

        if observedSettings.showUDPPorts != previousSettings.showUDPPorts {
            refreshPorts()
        }

        if menuAffectingPreferenceKeys.contains(key) {
            updateMenu()
        }
    }

    private func handleObservedDefaultsChange() {
        let previousSettings = observedSettings
        let currentSettings = currentObservedSettings()
        guard currentSettings != previousSettings else {
            return
        }

        observedSettings = currentSettings

        if currentSettings.refreshInterval != previousSettings.refreshInterval {
            configureRefreshTimer()
        }

        if currentSettings.showUDPPorts != previousSettings.showUDPPorts {
            refreshPorts()
        }

        let menuNeedsUpdate =
            currentSettings.showSystemProcesses != previousSettings.showSystemProcesses ||
            currentSettings.groupByCategory != previousSettings.groupByCategory ||
            currentSettings.groupByProcess != previousSettings.groupByProcess ||
            currentSettings.groupByApp != previousSettings.groupByApp

        if menuNeedsUpdate {
            updateMenu()
        }
    }

    private func currentObservedSettings() -> ObservedSettings {
        ObservedSettings(
            refreshInterval: refreshInterval,
            showSystemProcesses: showSystemProcesses,
            showUDPPorts: showUDPPorts,
            groupByCategory: groupByCategory,
            groupByProcess: groupByProcess,
            groupByApp: groupByApp,
        )
    }

    private func configureRefreshTimer() {
        refreshTimer?.cancel()
        refreshTimer = nil

        guard refreshInterval > 0 else {
            AppLogger.shared.log("Auto-refresh disabled (Manual mode)")
            return
        }

        AppLogger.shared.log("Auto-refresh enabled (\(Int(refreshInterval))s)")
        refreshTimer = Timer
            .publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshPorts()
            }
    }

    func refreshPorts() {
        guard !isLoading else {
            AppLogger.shared.log("Already loading, skipping refresh")
            return
        }

        AppLogger.shared.log("Starting port scan...")
        isLoading = true
        lastError = nil

        let includeUDP = showUDPPorts
        Task {
            let portInfoEnhancer = PortInfoEnhancer()
            AppLogger.shared.log("Calling portScanner.scanOpenPorts(includeUDP: \(includeUDP))")
            let result = await portScanner.scanOpenPorts(includeUDP: includeUDP)
            AppLogger.shared.log("Port scanner result - success: \(result.success), ports count: \(result.ports.count)")

            if result.success {
                AppLogger.shared.log("Resolving process info for \(result.ports.count) ports")
                let resolvedPorts = await processResolver.resolveProcessInfo(for: result.ports)
                AppLogger.shared.log("Process resolution complete, resolved ports count: \(resolvedPorts.count)")

                AppLogger.shared.log("Enhancing ports with safety and metadata")
                let enhancedPorts = await portInfoEnhancer.enhance(resolvedPorts)
                AppLogger.shared.log("Port enhancement complete, enhanced ports count: \(enhancedPorts.count)")

                await MainActor.run {
                    self.previousPorts = self.ports
                    self.ports = enhancedPorts
                    self.lastError = nil
                    self.lastUpdatedAt = Date()
                    self.isLoading = false
                    self.checkNotifications()
                }
            } else {
                let errorMsg = result.error ?? "Unknown error"
                AppLogger.shared.log("Port scan failed: \(errorMsg)")
                await MainActor.run {
                    self.ports = []
                    self.lastError = errorMsg
                    self.lastUpdatedAt = Date()
                    self.isLoading = false
                }
            }
        }
    }

    private func checkNotifications() {
        let notificationManager = NotificationManager.shared
        notificationManager.checkForNewPorts(ports)
        notificationManager.checkSecurityAlerts(ports)
        notificationManager.checkHighPortCount(ports)
    }

    func terminateProcess(pid: Int, signal: Signal) async {
        AppLogger.shared.log("Attempting to terminate process \(pid) with signal: \(signal.rawValue)")

        do {
            let result = try await processManager.terminateProcess(pid: pid, signal: signal)
            AppLogger.shared.log("Process termination result: \(result)")

            try? await Task.sleep(nanoseconds: 500_000_000)
            refreshPorts()
        } catch {
            AppLogger.shared.log("Failed to terminate process \(pid): \(error.localizedDescription)")
        }
    }

    func toggleFavorite(port: Int) {
        FavoritesManager.shared.toggleFavorite(port)
        updateMenu()
    }

    func exportPorts(format: ExportFormat) {
        Task {
            let content = await portExporter.export(ports: ports, format: format)
            guard let fileURL = await portExporter.saveToFile(content, filename: "export", format: format) else {
                AppLogger.shared.error("Failed to save export file")
                return
            }

            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            AppLogger.shared.log("Exported ports as \(format.rawValue) to \(fileURL.path)")
        }
    }

    private func updateMenu() {
        guard let statusItemController else {
            AppLogger.shared.log("statusItemController is nil, cannot update menu")
            return
        }

        AppLogger.shared.log("Updating menu with \(ports.count) ports, error: \(lastError ?? "none")")

        statusItemController.updateStatusIcon(ports: ports, hasWarnings: lastError != nil)
        statusItemController.updateState(portCount: ports.count, isLoading: isLoading, lastUpdatedAt: lastUpdatedAt)

        let favorites = FavoritesManager.shared.favorites
        let descriptor = MenuDescriptor().build(
            ports: ports,
            searchText: searchText,
            showSystemProcesses: showSystemProcesses,
            errorMessage: lastError,
            isLoading: isLoading,
            groupByCategory: groupByCategory,
            groupByProcess: groupByProcess,
            groupByApp: groupByApp,
            lastUpdatedAt: lastUpdatedAt,
            favoritePorts: favorites,
        )

        statusItemController.updateMenu(descriptor)
        statusItemController.updateFavoritePorts(favorites)
        AppLogger.shared.log("Menu updated successfully")
    }

    func toggleShowSystemProcesses() {
        updateMenu()
    }

    func toggleGroupByCategory() {
        updateMenu()
    }

    func updateMenuWithLoadingState() {
        guard let statusItemController else {
            return
        }

        let descriptor = MenuDescriptor().build(
            ports: [],
            searchText: "",
            showSystemProcesses: showSystemProcesses,
            errorMessage: nil,
            isLoading: true,
            lastUpdatedAt: nil,
        )
        statusItemController.updateMenu(descriptor)
        statusItemController.updateState(portCount: 0, isLoading: true, lastUpdatedAt: nil)
    }
}
