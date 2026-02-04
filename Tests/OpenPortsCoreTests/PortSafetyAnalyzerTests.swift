import XCTest
@testable import OpenPortsCore

final class PortSafetyAnalyzerTests: XCTestCase {

    let analyzer = PortSafetyAnalyzer()

    func testCriticalPortSSH() {
        let port = PortInfo(
            port: 22,
            portProtocol: .tcp,
            pid: 1234,
            processName: "sshd",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/sbin/sshd",
            isSystemProcess: true
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .critical)
    }

    func testCriticalPortHTTP() {
        let port = PortInfo(
            port: 80,
            portProtocol: .tcp,
            pid: 1234,
            processName: "nginx",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/local/bin/nginx",
            isSystemProcess: false
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .critical)
    }

    func testCriticalPortHTTPS() {
        let port = PortInfo(
            port: 443,
            portProtocol: .tcp,
            pid: 1234,
            processName: "httpd",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/sbin/httpd",
            isSystemProcess: false
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .critical)
    }

    func testImportantPortPostgreSQL() {
        let port = PortInfo(
            port: 5432,
            portProtocol: .tcp,
            pid: 1234,
            processName: "postgres",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/local/bin/postgres",
            isSystemProcess: false
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .important)
    }

    func testImportantPortMySQL() {
        let port = PortInfo(
            port: 3306,
            portProtocol: .tcp,
            pid: 1234,
            processName: "mysqld",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/local/bin/mysql",
            isSystemProcess: false
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .important)
    }

    func testUserCreatedPortNode3000() {
        let port = PortInfo(
            port: 3000,
            portProtocol: .tcp,
            pid: 1234,
            processName: "node",
            appName: nil,
            bundleID: nil,
            executablePath: "/Users/test/node",
            isSystemProcess: false,
            safety: nil,
            uptime: 120,
            isNew: true
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .userCreated)
    }

    func testUserCreatedPortPython5000() {
        let port = PortInfo(
            port: 5000,
            portProtocol: .tcp,
            pid: 1234,
            processName: "python",
            appName: nil,
            bundleID: nil,
            executablePath: "/Users/test/manage.py",
            isSystemProcess: false,
            safety: nil,
            uptime: 150,
            isNew: true
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .userCreated)
    }

    func testOptionalPortUserApp() {
        let port = PortInfo(
            port: 8080,
            portProtocol: .tcp,
            pid: 1234,
            processName: "MyApp",
            appName: "My Application",
            bundleID: "com.example.myapp",
            executablePath: "/Applications/MyApp.app/Contents/MacOS/MyApp",
            isSystemProcess: false,
            safety: nil,
            uptime: 3600,
            isNew: false
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .optional)
    }

    func testCriticalSystemProcess() {
        let port = PortInfo(
            port: 8080,
            portProtocol: .tcp,
            pid: 1234,
            processName: "mDNSResponder",
            appName: nil,
            bundleID: "com.apple.mDNSResponder",
            executablePath: "/usr/sbin/mDNSResponder",
            isSystemProcess: true
        )

        let safety = analyzer.analyze(port)
        XCTAssertEqual(safety, .critical)
    }

    func testSafetyDescriptionCritical() {
        let port = PortInfo(
            port: 22,
            portProtocol: .tcp,
            pid: 1,
            processName: "sshd",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/sbin/sshd",
            isSystemProcess: true
        )

        let description = analyzer.getSafetyDescription(port)
        XCTAssertNotNil(description)
    }

    func testSafetyDescriptionImportant() {
        let port = PortInfo(
            port: 5432,
            portProtocol: .tcp,
            pid: 1,
            processName: "postgres",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/local/bin/postgres",
            isSystemProcess: false
        )

        let description = analyzer.getSafetyDescription(port)
        XCTAssertNotNil(description)
    }

    func testShouldShowWarning() {
        let port = PortInfo(
            port: 5432,
            portProtocol: .tcp,
            pid: 1,
            processName: "postgres",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/local/bin/postgres",
            isSystemProcess: false
        )

        let shouldWarnHighRiskOnly = analyzer.shouldShowWarning(for: port, warningLevel: .highRiskOnly)
        XCTAssertTrue(shouldWarnHighRiskOnly)

        let shouldWarnAll = analyzer.shouldShowWarning(for: port, warningLevel: .all)
        XCTAssertTrue(shouldWarnAll)

        let shouldWarnNone = analyzer.shouldShowWarning(for: port, warningLevel: .none)
        XCTAssertFalse(shouldWarnNone)
    }

    func testSafetyIcons() {
        XCTAssertEqual(PortSafety.critical.icon, "🔴")
        XCTAssertEqual(PortSafety.important.icon, "🟠")
        XCTAssertEqual(PortSafety.optional.icon, "🟢")
        XCTAssertEqual(PortSafety.userCreated.icon, "🔵")
    }

    func testSafetyColors() {
        XCTAssertEqual(PortSafety.critical.color, "#F44336")
        XCTAssertEqual(PortSafety.important.color, "#FF9800")
        XCTAssertEqual(PortSafety.optional.color, "#4CAF50")
        XCTAssertEqual(PortSafety.userCreated.color, "#2196F3")
    }
}
