import XCTest
@testable import Persistence

final class PersistenceTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(Persistence.self)
    }
}
