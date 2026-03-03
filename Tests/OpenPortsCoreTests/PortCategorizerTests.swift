@testable import OpenPortsCore
import XCTest

final class PortCategorizerTests: XCTestCase {
    private let categorizer = PortCategorizer()

    func testDetectProjectNameIgnoresSystemPathComponents() {
        let port = PortInfo(
            port: 5000,
            portProtocol: .tcp,
            pid: 999,
            processName: "ControlCe",
            appName: "Control Center",
            bundleID: "com.apple.controlcenter",
            executablePath: "/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter",
            isSystemProcess: true,
        )

        let categorized = categorizer.categorize(port)
        XCTAssertNil(categorized.projectName)
    }

    func testDetectProjectNameFromUserDevelopmentPath() {
        let port = PortInfo(
            port: 5173,
            portProtocol: .tcp,
            pid: 123,
            processName: "python3",
            appName: nil,
            bundleID: nil,
            executablePath: "/Users/alex/code/my-api/.venv/bin/python3",
            isSystemProcess: false,
        )

        let categorized = categorizer.categorize(port)
        XCTAssertEqual(categorized.projectName, "my-api")
    }

    func testDetectProjectNameSkipsNodeModulesAndDotFolders() {
        let port = PortInfo(
            port: 3000,
            portProtocol: .tcp,
            pid: 321,
            processName: "node",
            appName: nil,
            bundleID: nil,
            executablePath: "/Users/alex/code/web-client/node_modules/.bin/vite",
            isSystemProcess: false,
        )

        let categorized = categorizer.categorize(port)
        XCTAssertEqual(categorized.projectName, "web-client")
    }
}
