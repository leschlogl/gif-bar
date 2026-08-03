import XCTest
@testable import Utilities

final class UtilitiesTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(Utilities.self)
    }
}
