import ServiceManagement

@MainActor
enum LaunchAtLoginManager {
    private static let serviceIdentifier = "com.mohamedmohana.openports.launcher"
    
    /// Check if app is set to launch at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    /// Enable or disable launch at login.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error.localizedDescription)")
        }
    }
}
