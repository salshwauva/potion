import XCTest
@testable import PotionCore

final class PotionCoreTests: XCTestCase {
    func testVersionIsPresent() {
        XCTAssertFalse(PotionCore.version.isEmpty)
    }
}
