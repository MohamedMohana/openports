@testable import OpenPortsCore
import UserNotifications
import XCTest

@MainActor
final class NotificationManagerTests: XCTestCase {
    func testInitialNonEmptyBaselineDoesNotTriggerNewPortAlert() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "notificationsEnabled")
        defaults.set(true, forKey: "newPortAlerts")

        var requests = [UNNotificationRequest]()
        let manager = NotificationManager(
            defaults: defaults,
            scheduleNotification: { requests.append($0) },
        )

        manager.checkForNewPorts([makePort(3000)])
        XCTAssertTrue(requests.isEmpty)

        manager.checkForNewPorts([makePort(3000), makePort(8080)])
        XCTAssertEqual(requests.map(\.identifier), ["new-port-8080"])
    }

    func testNewPortAlertFiresAfterEmptyBaseline() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "notificationsEnabled")
        defaults.set(true, forKey: "newPortAlerts")

        var requests = [UNNotificationRequest]()
        let manager = NotificationManager(
            defaults: defaults,
            scheduleNotification: { requests.append($0) },
        )

        manager.checkForNewPorts([])
        XCTAssertTrue(requests.isEmpty)

        manager.checkForNewPorts([makePort(3000)])
        XCTAssertEqual(requests.map(\.identifier), ["new-port-3000"])

        manager.checkForNewPorts([])
        manager.checkForNewPorts([makePort(3000)])
        XCTAssertEqual(requests.map(\.identifier), ["new-port-3000", "new-port-3000"])
    }

    func testNewPortBaselineTracksWhileAlertsAreDisabled() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(false, forKey: "notificationsEnabled")
        defaults.set(false, forKey: "newPortAlerts")

        var requests = [UNNotificationRequest]()
        let manager = NotificationManager(
            defaults: defaults,
            scheduleNotification: { requests.append($0) },
        )

        manager.checkForNewPorts([makePort(3000)])

        defaults.set(true, forKey: "notificationsEnabled")
        defaults.set(true, forKey: "newPortAlerts")

        manager.checkForNewPorts([makePort(3000)])
        XCTAssertTrue(requests.isEmpty)

        manager.checkForNewPorts([makePort(3000), makePort(8080)])
        XCTAssertEqual(requests.map(\.identifier), ["new-port-8080"])
    }

    func testSecurityAlertSignatureResetsWhenRiskClears() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "notificationsEnabled")
        defaults.set(true, forKey: "securityAlerts")

        var requests = [UNNotificationRequest]()
        let manager = NotificationManager(
            defaults: defaults,
            scheduleNotification: { requests.append($0) },
        )

        let criticalPort = makePort(22, safety: .critical)

        manager.checkSecurityAlerts([criticalPort])
        XCTAssertEqual(requests.count, 1)

        manager.checkSecurityAlerts([criticalPort])
        XCTAssertEqual(requests.count, 1)

        manager.checkSecurityAlerts([])
        manager.checkSecurityAlerts([criticalPort])
        XCTAssertEqual(requests.count, 2)
    }

    func testHighPortCountAlertsFireOnFirstSpikeAndAfterReset() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: "notificationsEnabled")
        defaults.set(true, forKey: "highPortCountAlerts")
        defaults.set(2, forKey: "portSpikeThreshold")

        var requests = [UNNotificationRequest]()
        var currentTime = Date(timeIntervalSince1970: 0)
        let manager = NotificationManager(
            defaults: defaults,
            scheduleNotification: { requests.append($0) },
            now: { currentTime },
        )

        let twoPorts = [makePort(3000), makePort(8080)]

        manager.checkHighPortCount(twoPorts)
        XCTAssertEqual(requests.map(\.identifier), ["high-port-count"])

        manager.checkHighPortCount(twoPorts)
        XCTAssertEqual(requests.count, 1)

        manager.checkHighPortCount([])
        manager.checkHighPortCount(twoPorts)
        XCTAssertEqual(requests.count, 2)

        currentTime = currentTime.addingTimeInterval(301)
        manager.checkHighPortCount(twoPorts)
        XCTAssertEqual(requests.count, 3)
    }

    func testHighPortCountBaselineTracksWhileAlertsAreDisabled() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(false, forKey: "notificationsEnabled")
        defaults.set(false, forKey: "highPortCountAlerts")
        defaults.set(2, forKey: "portSpikeThreshold")

        var requests = [UNNotificationRequest]()
        let manager = NotificationManager(
            defaults: defaults,
            scheduleNotification: { requests.append($0) },
        )

        let twoPorts = [makePort(3000), makePort(8080)]
        manager.checkHighPortCount(twoPorts)

        defaults.set(true, forKey: "notificationsEnabled")
        defaults.set(true, forKey: "highPortCountAlerts")

        manager.checkHighPortCount(twoPorts)
        XCTAssertTrue(requests.isEmpty)
    }

    private func makeDefaults() -> (UserDefaults, String) {
        let suiteName = "NotificationManagerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return (defaults, suiteName)
    }

    private func makePort(
        _ port: Int,
        safety: PortSafety? = nil,
        isSystemProcess: Bool = false,
    ) -> PortInfo {
        PortInfo(
            port: port,
            portProtocol: .tcp,
            pid: port,
            processName: "test-\(port)",
            appName: nil,
            bundleID: nil,
            executablePath: nil,
            isSystemProcess: isSystemProcess,
            safety: safety,
            uptime: nil,
            isNew: false,
        )
    }
}
