@testable import OpenPortsCLI
import OpenPortsCore
import XCTest

final class PortTableFormatterTests: XCTestCase {
    let formatter = PortTableFormatter()

    private func makePort(
        port: Int,
        portProtocol: PortInfo.PortProtocol = .tcp,
        pid: Int = 1234,
        processName: String = "node",
        appName: String? = nil,
        safety: PortSafety? = nil,
        uptime: TimeInterval? = nil,
    ) -> PortInfo {
        PortInfo(
            port: port,
            portProtocol: portProtocol,
            pid: pid,
            processName: processName,
            appName: appName,
            bundleID: nil,
            executablePath: nil,
            isSystemProcess: false,
            safety: safety,
            uptime: uptime,
            isNew: false,
        )
    }

    func testEmptyListRendersHeaderOnly() {
        let output = formatter.render([])

        XCTAssertEqual(output.components(separatedBy: "\n").count, 1)
        XCTAssertTrue(output.hasPrefix("PORT"))
    }

    func testRendersOneLinePerPort() {
        let output = formatter.render([
            makePort(port: 3000),
            makePort(port: 5432, processName: "postgres"),
        ])

        let lines = output.components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[1].contains("3000"))
        XCTAssertTrue(lines[1].contains("node"))
        XCTAssertTrue(lines[2].contains("5432"))
        XCTAssertTrue(lines[2].contains("postgres"))
    }

    func testRendersMetadataColumns() {
        let output = formatter.render([
            makePort(
                port: 8080,
                portProtocol: .udp,
                pid: 42,
                processName: "python3",
                appName: "MyApp",
                safety: .userCreated,
                uptime: 120,
            ),
        ])

        let row = output.components(separatedBy: "\n")[1]
        XCTAssertTrue(row.contains("UDP"))
        XCTAssertTrue(row.contains("42"))
        XCTAssertTrue(row.contains("MyApp"))
        XCTAssertTrue(row.contains("User-Created"))
        XCTAssertTrue(row.contains("2m"))
    }

    func testMissingValuesRenderAsDash() {
        let output = formatter.render([makePort(port: 80)])

        let row = output.components(separatedBy: "\n")[1]
        XCTAssertTrue(row.contains(" - "))
    }

    func testColumnsAreAligned() throws {
        let output = formatter.render([
            makePort(port: 80, pid: 1),
            makePort(port: 65535, pid: 99999, processName: "long-process-name"),
        ])

        let lines = output.components(separatedBy: "\n")
        // Every line places PROTO at the same offset as the header does.
        let headerProtoOffset = try XCTUnwrap(lines[0].range(of: "PROTO")?.lowerBound.utf16Offset(in: lines[0]))
        for line in lines.dropFirst() {
            let protoOffset = try XCTUnwrap(line.range(of: "TCP")?.lowerBound.utf16Offset(in: line))
            XCTAssertEqual(protoOffset, headerProtoOffset)
        }
    }

    func testNoTrailingWhitespace() {
        let output = formatter.render([makePort(port: 3000, uptime: 30)])

        for line in output.components(separatedBy: "\n") {
            XCTAssertEqual(line, line.replacingOccurrences(of: #"\s+$"#, with: "", options: .regularExpression))
        }
    }
}
