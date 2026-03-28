import Combine
import Foundation
import Logging
import UserNotifications

@MainActor
public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()

    private let defaults = UserDefaults.standard
    private let logger = Logger(label: "com.openports.notifications")

    var notificationsEnabled: Bool {
        defaults.bool(forKey: "notificationsEnabled")
    }

    var newPortAlerts: Bool {
        defaults.bool(forKey: "newPortAlerts")
    }

    var highPortCountAlerts: Bool {
        defaults.bool(forKey: "highPortCountAlerts")
    }

    var securityAlerts: Bool {
        defaults.bool(forKey: "securityAlerts")
    }

    var portSpikeThreshold: Int {
        defaults.integer(forKey: "portSpikeThreshold")
    }

    private var lastNotifiedPorts: Set<Int> = []
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

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge],
        ) { [weak self] granted, _ in
            if granted {
                self?.logger.info("Notifications authorized")
            }
        }
    }

    public func checkForNewPorts(_ currentPorts: [PortInfo]) {
        guard notificationsEnabled, newPortAlerts else { return }

        let currentPortNumbers = Set(currentPorts.map(\.port))
        let newPorts = currentPortNumbers.subtracting(lastNotifiedPorts)

        if !lastNotifiedPorts.isEmpty, !newPorts.isEmpty {
            for portNum in newPorts.sorted() {
                if let port = currentPorts.first(where: { $0.port == portNum }) {
                    notifyNewPort(port: port.port, processName: port.displayName)
                }
            }
        }

        lastNotifiedPorts = currentPortNumbers
    }

    public func checkSecurityAlerts(_ ports: [PortInfo]) {
        guard notificationsEnabled, securityAlerts else { return }

        let highRiskPorts = ports.filter {
            $0.safety == .critical && !$0.isSystemProcess
        }

        let signature = highRiskPorts.map(\.port).sorted().map(String.init).joined(separator: ",")

        guard !highRiskPorts.isEmpty, signature != lastSecurityAlertSignature else { return }

        lastSecurityAlertSignature = signature
        let names = highRiskPorts.prefix(3).map { ":\($0.port) \($0.displayName)" }
        let message = "High-risk services: \(names.joined(separator: ", "))"
        notifySecurityAlert(message: message)
    }

    public func checkHighPortCount(_ ports: [PortInfo]) {
        guard notificationsEnabled, highPortCountAlerts else { return }

        guard ports.count >= portSpikeThreshold else { return }

        if let lastNotification = lastPortCountNotification {
            guard Date().timeIntervalSince(lastNotification) > 300 else { return }
        }

        notifyHighPortCount(count: ports.count)
        lastPortCountNotification = Date()
    }

    private func notifyNewPort(port: Int, processName: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Port Opened"
        content.body = ":\(port) - \(processName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "new-port-\(port)",
            content: content,
            trigger: nil,
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func notifySecurityAlert(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Security Alert"
        content.body = message
        content.sound = .defaultCritical

        let request = UNNotificationRequest(
            identifier: "security-\(UUID().uuidString)",
            content: content,
            trigger: nil,
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func notifyHighPortCount(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "High Port Count"
        content.body = "\(count) ports currently open (threshold: \(portSpikeThreshold))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "high-port-count",
            content: content,
            trigger: nil,
        )

        UNUserNotificationCenter.current().add(request)
    }
}
