@testable import OpenPortsCore
import XCTest

final class PortInfoEnhancerTests: XCTestCase {
    private func components(of date: Date) -> DateComponents {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    }

    func testParseStartTimeWithSingleDigitDay() throws {
        // ps pads single-digit days with an extra space: "Jul  4"
        let date = try XCTUnwrap(PortInfoEnhancer.parseProcessStartTime("Sat Jul  4 04:09:00 2026"))

        let parsed = components(of: date)
        XCTAssertEqual(parsed.year, 2026)
        XCTAssertEqual(parsed.month, 7)
        XCTAssertEqual(parsed.day, 4)
        XCTAssertEqual(parsed.hour, 4)
        XCTAssertEqual(parsed.minute, 9)
        XCTAssertEqual(parsed.second, 0)
    }

    func testParseStartTimeWithDoubleDigitDay() throws {
        let date = try XCTUnwrap(PortInfoEnhancer.parseProcessStartTime("Wed Jul 15 21:30:45 2026"))

        let parsed = components(of: date)
        XCTAssertEqual(parsed.year, 2026)
        XCTAssertEqual(parsed.month, 7)
        XCTAssertEqual(parsed.day, 15)
        XCTAssertEqual(parsed.hour, 21)
        XCTAssertEqual(parsed.minute, 30)
        XCTAssertEqual(parsed.second, 45)
    }

    func testParseStartTimeWithSurroundingWhitespace() throws {
        let date = try XCTUnwrap(PortInfoEnhancer.parseProcessStartTime("  Mon Jan  5 00:00:01 2026\n"))

        let parsed = components(of: date)
        XCTAssertEqual(parsed.month, 1)
        XCTAssertEqual(parsed.day, 5)
    }

    func testParseStartTimeAgainstLivePsOutput() throws {
        // Parse real ps output for the current process and sanity-check the result.
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", String(ProcessInfo.processInfo.processIdentifier), "-o", "lstart="]

        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = try XCTUnwrap(String(data: data, encoding: .utf8))

        let date = try XCTUnwrap(PortInfoEnhancer.parseProcessStartTime(output))
        let uptime = Date().timeIntervalSince(date)
        XCTAssertGreaterThanOrEqual(uptime, 0)
        XCTAssertLessThan(uptime, 60 * 60 * 24, "test process should have started within the last day")
    }

    func testParseStartTimeWithEmptyOutput() {
        XCTAssertNil(PortInfoEnhancer.parseProcessStartTime(""))
        XCTAssertNil(PortInfoEnhancer.parseProcessStartTime("   \n"))
    }

    func testParseStartTimeWithInvalidOutput() {
        XCTAssertNil(PortInfoEnhancer.parseProcessStartTime("not a date"))
        // Old bug: pid column appended after the date must not parse silently wrong
        XCTAssertNil(PortInfoEnhancer.parseProcessStartTime("Sat Jul  4 04:09:00 2026     21308"))
    }

    func testEnhancePopulatesUptimeForLiveProcess() async throws {
        let enhancer = PortInfoEnhancer()
        let pid = Int(ProcessInfo.processInfo.processIdentifier)
        let port = PortInfo(
            port: 8080,
            portProtocol: .tcp,
            pid: pid,
            processName: "xctest",
            appName: nil,
            bundleID: nil,
            executablePath: nil,
            isSystemProcess: false,
        )

        let enhanced = await enhancer.enhance([port])

        XCTAssertEqual(enhanced.count, 1)
        let uptime = try XCTUnwrap(enhanced[0].uptime, "uptime should be resolved for a live process")
        XCTAssertGreaterThanOrEqual(uptime, 0)
    }
}
