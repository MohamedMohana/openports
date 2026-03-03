import AppKit
import Combine
import Foundation
import OpenPortsCore

/// ViewModel for managing menu state and data.
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

    private let portScanner: PortScanner
    private let processResolver: ProcessResolver
    private let processManager: ProcessManager
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: AnyCancellable?

    private let userDefaults = UserDefaults.standard
    private var refreshInterval: Double {
        userDefaults.double(forKey: AppSettingsKey.refreshInterval)
    }

    private var showSystemProcesses: Bool {
        userDefaults.bool(forKey: AppSettingsKey.showSystemProcesses)
    }

    private var groupByCategory: Bool {
        userDefaults.bool(forKey: AppSettingsKey.groupByCategory)
    }

    private var groupByProcess: Bool {
        userDefaults.bool(forKey: AppSettingsKey.groupByProcess)
    }

    var statusItemController: StatusItemController?

    init(
        portScanner: PortScanner,
        processResolver: ProcessResolver,
        processManager: ProcessManager,
    ) {
        self.portScanner = portScanner
        self.processResolver = processResolver
        self.processManager = processManager
        AppSettings.registerDefaults(userDefaults: userDefaults)

        setupNotifications()
        configureRefreshTimer()
        // Note: Initial refresh is triggered by AppDelegate after statusItemController is set
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

        // Observe preference changes from PreferencesView
        NotificationCenter.default.publisher(for: .preferenceChanged)
            .sink { [weak self] notification in
                if let key = notification.object as? String {
                    AppLogger.shared.log("Preference changed via notification: \(key)")
                    self?.handlePreferenceChange(for: key)
                }
            }
            .store(in: &cancellables)

        // Observe UserDefaults changes as backup
        observeUserDefaultsChanges()
    }

    private func observeUserDefaultsChanges() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: userDefaults)
            .sink { [weak self] notification in
                guard notification.object is UserDefaults else { return }
                self?.configureRefreshTimer()
                self?.updateMenu()
            }
            .store(in: &cancellables)
    }

    private func handlePreferenceChange(for key: String) {
        guard AppSettingsKey.trackedPreferenceKeys.contains(key) else {
            return
        }

        if key == AppSettingsKey.refreshInterval {
            configureRefreshTimer()
        }

        updateMenu()
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

        Task {
            let portInfoEnhancer = PortInfoEnhancer()
            AppLogger.shared.log("Calling portScanner.scanOpenPorts()")
            let result = await portScanner.scanOpenPorts()
            AppLogger.shared.log("Port scanner result - success: \(result.success), ports count: \(result.ports.count)")

            if result.success {
                AppLogger.shared.log("Resolving process info for \(result.ports.count) ports")
                let resolvedPorts = await processResolver.resolveProcessInfo(for: result.ports)
                AppLogger.shared.log("Process resolution complete, resolved ports count: \(resolvedPorts.count)")

                AppLogger.shared.log("Enhancing ports with safety and metadata")
                let enhancedPorts = await portInfoEnhancer.enhance(resolvedPorts)
                AppLogger.shared.log("Port enhancement complete, enhanced ports count: \(enhancedPorts.count)")

                await MainActor.run {
                    self.ports = enhancedPorts
                    self.lastError = nil
                    self.lastUpdatedAt = Date()
                    self.isLoading = false
                    self.updateMenu()
                }
            } else {
                let errorMsg = result.error ?? "Unknown error"
                AppLogger.shared.log("Port scan failed: \(errorMsg)")
                await MainActor.run {
                    self.ports = []
                    self.lastError = errorMsg
                    self.lastUpdatedAt = Date()
                    self.isLoading = false
                    self.updateMenu()
                }
            }
        }
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

    private func updateMenu() {
        guard let statusItemController else {
            AppLogger.shared.log("statusItemController is nil, cannot update menu")
            return
        }

        AppLogger.shared.log("Updating menu with \(ports.count) ports, error: \(lastError ?? "none")")

        // Update status bar icon first
        statusItemController.updateStatusIcon(ports: ports, hasWarnings: lastError != nil)

        let descriptor = MenuDescriptor().build(
            ports: ports,
            searchText: "",
            showSystemProcesses: showSystemProcesses,
            errorMessage: lastError,
            isLoading: isLoading,
            groupByCategory: groupByCategory,
            groupByProcess: groupByProcess,
            lastUpdatedAt: lastUpdatedAt,
        )

        statusItemController.updateMenu(descriptor)
        AppLogger.shared.log("Menu updated successfully")
    }

    func toggleShowSystemProcesses() {
        updateMenu()
    }

    func toggleGroupByCategory() {
        updateMenu()
    }

    /// Show loading state immediately without triggering a refresh
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
    }
}
