import Foundation
import UserNotifications

import UserNotifications

/// Manages smart notifications for OpenPorts
public class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()
    
    @Published private(set) notificationsEnabled: Bool = true
    @Published private(set) newPortAlerts: Bool = false
    @Published private(set) highPortCountAlerts: Bool = true
    @Published private(set) securityAlerts: Bool = true
    
    public init() {
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            if granted {
                print("✅ Notifications authorized")
            }
        }
    }
    
    public func notifyNewPort(port: Int, processName: String) {
        guard notificationsEnabled && newPortAlerts else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Port Opened"
        content.body = ":\(port) - \(processName)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "new-port-\(port)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    public func notifySecurityAlert(message: String) {
        guard notificationsEnabled && securityAlerts else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Security Alert"
        content.body = message
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    public func notifyHighPortCount(count: Int) {
        guard notificationsEnabled && highPortCountAlerts else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "High Port Count"
        content.body = "\(count) ports currently open"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "high-port-count",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
