import AppKit
import Foundation

extension AppDelegate {
    func application(_: NSApplication, open url: URL) -> Bool {
        guard url.scheme == "openports" else { return true }

        switch url.host?.lowercased() {
        case "refresh":
            NotificationCenter.default.post(name: .refreshPorts, object: nil)

        case "kill":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []

            guard
                let portValue = queryItems.first(where: { $0.name == "port" })?.value,
                let port = Int(portValue)
            else {
                return false
            }

            let forceValue = queryItems.first(where: { $0.name == "force" })?.value ?? "false"
            let isForceKill = ["1", "true", "yes"].contains(forceValue.lowercased())
            let notificationName: Notification.Name = isForceKill ? .forceKill : .terminatePort
            NotificationCenter.default.post(name: notificationName, object: port)

        default:
            break
        }

        return true
    }
}
