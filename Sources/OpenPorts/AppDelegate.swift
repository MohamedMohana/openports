import AppKit
import SwiftUI
import OpenPortsCore

extension AppDelegate {
    func application(_ application: NSApplication, open url: URL) -> Bool {
        guard url.scheme == "openports" else { return true }
        
        switch url.host {
        case "refresh":
            NotificationCenter.default.post(name: .refreshPorts, object: nil)
            
        case "kill":
            if let port = Int(url.query ?? ""),
               let force = url.query == "true" {
                NotificationCenter.default.post(name: .forceKill, object: port)
            } else {
                NotificationCenter.default.post(name: .terminatePort, object: port)
            }
            
        case "export":
            NotificationCenter.default.post(name: .exportPorts, object: url.query)
            
        case "search":
            NotificationCenter.default.post(name: .searchPorts, object: url.query)
            
        default:
            break
        }
        
        return true
    }
}
