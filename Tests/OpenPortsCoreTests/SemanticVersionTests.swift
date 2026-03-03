@testable import OpenPortsCore
import XCTest

final class SemanticVersionTests: XCTestCase {
    func testVersionParsesWithPrefixAndPrereleaseSuffix() {
        let version = SemanticVersion("v2.0.1-beta.1")
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.components, [2, 0, 1])
    }

    func testVersionComparisonAcrossDifferentSegmentCounts() {
        let newer = SemanticVersion("2.0.1")
        let older = SemanticVersion("2.0")
        XCTAssertNotNil(newer)
        XCTAssertNotNil(older)
        XCTAssertTrue(newer! > older!)
    }

    func testVersionComparisonWithMajorMinorPatch() {
        let newer = SemanticVersion("3.1.0")
        let older = SemanticVersion("3.0.9")
        XCTAssertNotNil(newer)
        XCTAssertNotNil(older)
        XCTAssertTrue(newer! > older!)
    }

    func testInvalidVersionReturnsNil() {
        XCTAssertNil(SemanticVersion(""))
        XCTAssertNil(SemanticVersion("main"))
        XCTAssertNil(SemanticVersion("v2.a.1"))
    }

    func testIsNewerHelper() {
        XCTAssertTrue(SemanticVersion.isNewer("v2.0.2", than: "2.0.1"))
        XCTAssertFalse(SemanticVersion.isNewer("2.0.1", than: "2.0.1"))
        XCTAssertFalse(SemanticVersion.isNewer("invalid", than: "2.0.1"))
    }
}
