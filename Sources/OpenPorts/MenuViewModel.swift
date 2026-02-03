import Foundation
import OpenPortsCore
import AppKit
import Combine

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

    private let portScanner: PortScanner
    private let processResolver: ProcessResolver
    private let processManager: ProcessManager
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private let userDefaults = UserDefaults.standard
    private var refreshInterval: Double {
        get { userDefaults.double(forKey: "refreshInterval") }
        set { userDefaults.set(newValue, forKey: "refreshInterval") }
    }
    private var showSystemProcesses: Bool {
        get { userDefaults.bool(forKey: "showSystemProcesses") }
        set { userDefaults.set(newValue, forKey: "showSystemProcesses") }
    }
    
    var statusItemController: StatusItemController?
    
    init(
        portScanner: PortScanner,
        processResolver: ProcessResolver,
        processManager: ProcessManager
    ) {
        self.portScanner = portScanner
        self.processResolver = processResolver
        self.processManager = processManager

        setupNotifications()
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
    }
    
    func refreshPorts() {
        AppLogger.shared.log("refreshPorts() called from: \(Thread.callStackSymbols[1])")
        guard !isLoading else {
            AppLogger.shared.log("Already loading, skipping refresh")
            return
        }

        AppLogger.shared.log("Starting port scan...")
        isLoading = true
        lastError = nil

        Task {
            AppLogger.shared.log("Calling portScanner.scanOpenPorts()")
            let result = await portScanner.scanOpenPorts()
            AppLogger.shared.log("Port scanner result - success: \(result.success), ports count: \(result.ports.count)")

            if result.success {
                AppLogger.shared.log("Resolving process info for \(result.ports.count) ports")
                let resolvedPorts = await processResolver.resolveProcessInfo(for: result.ports)
                AppLogger.shared.log("Process resolution complete, resolved ports count: \(resolvedPorts.count)")

                await MainActor.run {
                    self.ports = resolvedPorts
                    self.lastError = nil
                    self.updateMenu()
                    self.isLoading = false
                }
            } else {
                let errorMsg = result.error ?? "Unknown error"
                AppLogger.shared.log("Port scan failed: \(errorMsg)")
                await MainActor.run {
                    self.ports = []
                    self.lastError = errorMsg
                    self.updateMenu()
                    self.isLoading = false
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
    
    private func startTimer() {
        AppLogger.shared.log("startTimer() called, current timer: \(refreshTimer != nil)")
        invalidateTimer()
        
        guard refreshInterval > 0 else {
            AppLogger.shared.log("Auto-refresh disabled (interval: \(refreshInterval))")
            return
        }
        
        AppLogger.shared.log("Starting refresh timer with interval: \(refreshInterval) seconds")
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: refreshInterval,
            repeats: true
        ) { [weak self] _ in
            AppLogger.shared.log("Timer fired, calling refreshPorts()")
            Task { @MainActor in
                self?.refreshPorts()
            }
        }
    }
    
    private func invalidateTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func updateMenu() {
        guard let statusItemController = statusItemController else {
            AppLogger.shared.log("statusItemController is nil, cannot update menu")
            return
        }

        AppLogger.shared.log("Updating menu with \(ports.count) ports, error: \(lastError ?? "none")")

        let descriptor = MenuDescriptor().build(
            ports: ports,
            searchText: "",
            showSystemProcesses: showSystemProcesses,
            errorMessage: lastError,
            isLoading: isLoading
        )

        statusItemController.updateMenu(descriptor)
        AppLogger.shared.log("Menu updated successfully")
    }
    
    func updateRefreshInterval() {
        startTimer()
    }
    
    func toggleShowSystemProcesses() {
        updateMenu()
    }

    /// Show loading state immediately without triggering a refresh
    func updateMenuWithLoadingState() {
        guard let statusItemController = statusItemController else {
            return
        }

        let descriptor = MenuDescriptor().build(
            ports: [],
            searchText: "",
            showSystemProcesses: showSystemProcesses,
            errorMessage: nil,
            isLoading: true
        )
        statusItemController.updateMenu(descriptor)
    }
}
