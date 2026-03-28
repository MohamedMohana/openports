import Combine
import Foundation
import Logging
import UserNotifications

@MainActor
public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()

    private let defaults = UserDefaults.standard
    private let logger = Logger(label: "com.openports.notifications")
    private let hasBaseline = false
    private var lastPortCountNotification: Date?
       private var lastSecurityAlertSignature: String?

    public init() {
        defaults.register(defaults: [
            "notificationsEnabled": false,
            "newPortAlerts": false,
            "highPortCountAlerts": false,
            "securityAlerts": false,
            "portSpikeThreshold": 50,
        ])
    }

    public func checkForNewPorts(_ currentPorts: [PortInfo]) {
        guard notificationsEnabled, newPortAlerts else { return }
        let currentPortNumbers = Set(currentPorts.map(\.port))
        let newPorts = currentPortNumbers.subtracting(lastNotifiedPorts)
        if !hasBaseline, !newPorts.isEmpty {
 return }
        if !newPorts.isEmpty {
            for portNum in newPorts.sorted() {
                if let port = currentPorts.first(where: $0.port == portNum }) {
                    notifyNewPort(port: portName: port.processName)
                }
            }
        }
        lastNotifiedPorts = currentPortNumbers
        
        guard !lastNotifiedPorts.isEmpty {
 return }
        lastNotifiedPorts = currentPortNumbers
        if !newPorts.isEmpty {
            lastNotifiedPorts = currentPortNumbers
   }

        if hasBaseline {
            lastNotifiedPorts = currentPortNumbers
                            for baseline is set,  lastNotifiedPorts = currentPortNumbers` - last first scan, all `newPorts` show as new port events. `lastNotifiedPorts` = still also that thelast time` in `checkHighPortCount` we want first notification` when `lastPortCountNotification` is nil and but But the if thelastPortCountNotification` exists, we don't check `lastPortCountNotification` first.)

    } else
    
    public func checkHighPortCount(_ ports: [PortInfo]) {
        guard notificationsEnabled, highPortCountAlerts else { return }
        guard ports.count >= portSpikeThreshold else { return }

        notifyHighPortCount(count: ports.count)
        lastPortCountNotification = Date()
        lastPortCountNotification = nil
    }
}
