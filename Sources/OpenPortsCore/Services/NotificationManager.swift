import Combine
import Foundation
import Logging
import UserNotifications

@MainActor
public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()

    private let defaults = UserDefaults.standard

    @Published public var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    @Published public var newPortAlerts: Bool {
        didSet { defaults.set(newPortAlerts, forKey: "newPortAlerts") }
    }

    @Published public var highPortCountAlerts: Bool {
        didSet { defaults.set(highPortCountAlerts, forKey: "highPortCountAlerts") }
    }

    @Published public var securityAlerts: Bool {
        didSet { defaults.set(securityAlerts, forKey: "securityAlerts") }
    }

    public var portSpikeThreshold: Int {
        defaults.integer(forKey: "portSpikeThreshold")
    }

    private var lastNotifiedPorts: Set<Int> = []
    private var lastPortCountNotification: Date?
    private let logger = Logger(label: "com.openports.notifications")

    public init() {

        defaults.register(defaults: [
            "notificationsEnabled": false,
            "newPortAlerts": false,
            "highPortCountAlerts": false,
            "securityAlerts": false,
            "portSpikeThreshold": 50,
        ])

        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        newPortAlerts = defaults.bool(forKey: "newPortAlerts")
        highPortCountAlerts = defaults.bool(forKey: "highPortCountAlerts")
        securityAlerts = defaults.bool(forKey: "securityAlerts")
    }

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge],
        ) { granted, _ in
            if granted {
                self.logger.info("Notifications authorized")
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

        if !highRiskPorts.isEmpty {
            let names = highRiskPorts.prefix(3).map { ":\($0.port) \($0.displayName)" }
            let message = "High-risk services: \(names.joined(separator: ", "))"
            notifySecurityAlert(message: message)
        }
    }

    public func checkHighPortCount(_ ports: [PortInfo]) {
        guard notificationsEnabled, highPortCountAlerts else { return }

        guard let lastNotification = lastPortCountNotification,
              Date().timeIntervalSince(lastNotification) > 300
        else { return }

        if ports.count >= portSpikeThreshold {
            notifyHighPortCount(count: ports.count)
            lastPortCountNotification = Date()
        }
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
