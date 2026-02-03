import XCTest
@testable import OpenPortsCore

final class OpenPortsCoreTests: XCTestCase {
    func testCoreInitialization() {
        XCTAssertNotNil(OpenPortsCore.version)
        XCTAssertEqual(OpenPortsCore.version, "1.0.0")
    }
}
