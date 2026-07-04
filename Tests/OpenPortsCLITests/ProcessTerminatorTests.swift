@testable import OpenPortsCLI
import XCTest

final class ProcessTerminatorTests: XCTestCase {
    let terminator = ProcessTerminator()

    func testTerminateNonexistentProcessReturnsNoSuchProcess() {
        // Far beyond macOS's PID_MAX (99999), so it can never name a live process.
        let result = terminator.terminate(pid: 99_999_999, signal: .term)

        guard case let .failure(error) = result else {
            return XCTFail("Expected failure for nonexistent PID")
        }
        XCTAssertEqual(error, .noSuchProcess)
    }

    func testTerminateRunningProcessSucceeds() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sleep")
        process.arguments = ["60"]
        try process.run()

        let result = terminator.terminate(pid: Int(process.processIdentifier), signal: .term)
        process.waitUntilExit()

        guard case .success = result else {
            return XCTFail("Expected SIGTERM to be delivered")
        }
        XCTAssertEqual(process.terminationReason, .uncaughtSignal)
    }
}
