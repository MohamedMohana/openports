import Foundation
import ServiceManagement

@MainActor
enum LaunchAtLoginManager {
    /// Scriptable control: `OpenPorts --set-launch-at-login on|off` and
    /// `OpenPorts --launch-at-login-status` print the state and exit.
    /// Run from the installed app bundle so the registration points at it.
    static func handleCommandLineIfRequested() {
        let arguments = CommandLine.arguments

        if let index = arguments.firstIndex(of: "--set-launch-at-login"), arguments.count > index + 1 {
            setEnabled(arguments[index + 1].lowercased() == "on")
            print("launch-at-login: \(isEnabled ? "enabled" : "disabled")")
            exit(0)
        }

        if arguments.contains("--launch-at-login-status") {
            print("launch-at-login: \(isEnabled ? "enabled" : "disabled")")
            exit(0)
        }
    }

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
