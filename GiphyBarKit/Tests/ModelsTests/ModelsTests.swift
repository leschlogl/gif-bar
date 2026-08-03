import XCTest
@testable import Models

final class ModelsTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(Models.self)
    }
}
