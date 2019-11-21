import XCTest
@testable import Nantes

final class NantesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Nantes().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
