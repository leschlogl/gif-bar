import XCTest
@testable import ViewModels

final class ViewModelsTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(ViewModels.self)
    }
}
