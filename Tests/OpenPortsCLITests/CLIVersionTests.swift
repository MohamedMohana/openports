@testable import OpenPortsCLI
import XCTest

final class CLIVersionTests: XCTestCase {
    /// `openports-cli --version` must report the same version as the packaged app.
    func testCLIVersionMatchesVersionEnv() throws {
        let versionEnvURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // OpenPortsCLITests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("version.env")

        let contents = try String(contentsOf: versionEnvURL, encoding: .utf8)
        let marketingVersion = contents
            .components(separatedBy: .newlines)
            .first { $0.hasPrefix("MARKETING_VERSION=") }?
            .replacingOccurrences(of: "MARKETING_VERSION=", with: "")

        XCTAssertEqual(
            CLIVersion.current,
            marketingVersion,
            "Update CLIVersion.current when bumping MARKETING_VERSION in version.env",
        )
    }
}
