@testable import OpenPortsCore
import XCTest

final class OpenPortsCoreTests: XCTestCase {
    func testCoreInitialization() {
        XCTAssertNotNil(OpenPortsCore.version)
        XCTAssertEqual(OpenPortsCore.version, "2.0.2")
    }
}
