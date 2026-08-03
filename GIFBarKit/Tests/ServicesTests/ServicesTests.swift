import XCTest
@testable import Services

final class ServicesTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(Services.self)
    }
}
