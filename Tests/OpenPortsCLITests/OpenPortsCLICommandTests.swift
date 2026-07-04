@testable import OpenPortsCLI
import OpenPortsCore
import XCTest

final class OpenPortsCLICommandTests: XCTestCase {
    // MARK: - Argument parsing

    func testDefaultsToTableFormatTCPOnly() throws {
        let command = try OpenPortsCLICommand.parse([])

        XCTAssertEqual(command.format, .table)
        XCTAssertFalse(command.udp)
        XCTAssertNil(command.kill)
        XCTAssertFalse(command.force)
        XCTAssertEqual(command.signal, .term)
    }

    func testParsesFormatOption() throws {
        XCTAssertEqual(try OpenPortsCLICommand.parse(["--format", "json"]).format, .json)
        XCTAssertEqual(try OpenPortsCLICommand.parse(["-f", "csv"]).format, .csv)
    }

    func testRejectsUnknownFormat() {
        XCTAssertThrowsError(try OpenPortsCLICommand.parse(["--format", "xml"]))
    }

    func testParsesKillOptions() throws {
        let command = try OpenPortsCLICommand.parse(["--kill", "3000", "--force", "--signal", "kill"])

        XCTAssertEqual(command.kill, 3000)
        XCTAssertTrue(command.force)
        XCTAssertEqual(command.signal, .kill)
    }

    func testRejectsOutOfRangeKillPort() {
        XCTAssertThrowsError(try OpenPortsCLICommand.parse(["--kill", "0"]))
        XCTAssertThrowsError(try OpenPortsCLICommand.parse(["--kill", "65536"]))
    }

    // MARK: - Output format mapping

    func testExportFormatMapping() {
        XCTAssertNil(OutputFormat.table.exportFormat)
        XCTAssertEqual(OutputFormat.json.exportFormat, .json)
        XCTAssertEqual(OutputFormat.csv.exportFormat, .csv)
    }

    // MARK: - Signals

    func testSignalMapping() {
        XCTAssertEqual(TerminationSignal.term.rawSignal, SIGTERM)
        XCTAssertEqual(TerminationSignal.kill.rawSignal, SIGKILL)
        XCTAssertEqual(TerminationSignal.term.displayName, "SIGTERM")
        XCTAssertEqual(TerminationSignal.kill.displayName, "SIGKILL")
    }
}
