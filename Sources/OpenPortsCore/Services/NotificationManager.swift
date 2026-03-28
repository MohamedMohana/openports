import Combine
import Foundation
import Logging
import UserNotifications

@MainActor
public final class NotificationManager: ObservableObject {
    public static let shared = NotificationManager()

    private let defaults: UserDefaults
    private let logger = Logger(label: "com.openports.notifications")
    private let scheduleNotification: (UNNotificationRequest) -> Void
    private let now: () -> Date

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
    private var hasNewPortBaseline = false
    private var isCurrentlyAbovePortThreshold = false
    private var lastPortCountNotification: Date?
    private var lastSecurityAlertSignature: String?

    public init(
        defaults: UserDefaults = .standard,
        scheduleNotification: ((UNNotificationRequest) -> Void)? = nil,
        now: @escaping () -> Date = Date.init,
    ) {
        self.defaults = defaults
        self.now = now
        self.scheduleNotification = scheduleNotification ?? { request in
            UNUserNotificationCenter.current().add(request)
        }

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
        let currentPortNumbers = Set(currentPorts.map(\.port))
        defer {
            lastNotifiedPorts = currentPortNumbers
            hasNewPortBaseline = true
        }

        guard notificationsEnabled, newPortAlerts else { return }
        guard hasNewPortBaseline else { return }

        let newPorts = currentPortNumbers.subtracting(lastNotifiedPorts)

        if !newPorts.isEmpty {
            for portNum in newPorts.sorted() {
                if let port = currentPorts.first(where: { $0.port == portNum }) {
                    notifyNewPort(port: port.port, processName: port.displayName)
                }
            }
        }
    }

    public func checkSecurityAlerts(_ ports: [PortInfo]) {
        let highRiskPorts = ports.filter {
            $0.safety == .critical && !$0.isSystemProcess
        }

        let signature: String? = if highRiskPorts.isEmpty {
            nil
        } else {
            highRiskPorts.map(\.port).sorted().map(String.init).joined(separator: ",")
        }

        defer {
            lastSecurityAlertSignature = signature
        }

        guard notificationsEnabled, securityAlerts else { return }
        guard let signature else { return }
        guard signature != lastSecurityAlertSignature else { return }

        let names = highRiskPorts.prefix(3).map { ":\($0.port) \($0.displayName)" }
        let message = "High-risk services: \(names.joined(separator: ", "))"
        notifySecurityAlert(message: message)
    }

    public func checkHighPortCount(_ ports: [PortInfo]) {
        let isAboveThreshold = ports.count >= portSpikeThreshold

        guard notificationsEnabled, highPortCountAlerts else {
            isCurrentlyAbovePortThreshold = isAboveThreshold
            if !isAboveThreshold {
                lastPortCountNotification = nil
            }
            return
        }

        guard isAboveThreshold else {
            isCurrentlyAbovePortThreshold = false
            lastPortCountNotification = nil
            return
        }

        let currentTime = now()

        if !isCurrentlyAbovePortThreshold {
            notifyHighPortCount(count: ports.count)
            lastPortCountNotification = currentTime
            isCurrentlyAbovePortThreshold = true
            return
        }

        if let lastNotification = lastPortCountNotification {
            guard currentTime.timeIntervalSince(lastNotification) > 300 else { return }
            notifyHighPortCount(count: ports.count)
            lastPortCountNotification = currentTime
            return
        }

        lastPortCountNotification = currentTime
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

        scheduleNotification(request)
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

        scheduleNotification(request)
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

        scheduleNotification(request)
    }
}
