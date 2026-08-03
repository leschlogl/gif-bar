import XCTest
@testable import Networking

final class NetworkingTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertNotNil(Networking.self)
    }
}
