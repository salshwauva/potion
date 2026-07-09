import XCTest
@testable import PotionCore

final class MascotStateTests: XCTestCase {
    func testIdleAtEmptyPrompt() {
        XCTAssertEqual(MascotState.classify(isRunning: false, isAlternateScreen: false, draftEmpty: true), .idle)
    }

    func testTypingWhenDraftPresent() {
        XCTAssertEqual(MascotState.classify(isRunning: false, isAlternateScreen: false, draftEmpty: false), .typing)
    }

    func testRunningWhenCommandActive() {
        XCTAssertEqual(MascotState.classify(isRunning: true, isAlternateScreen: false, draftEmpty: true), .running)
    }

    func testAlternateScreenCountsAsRunning() {
        XCTAssertEqual(MascotState.classify(isRunning: false, isAlternateScreen: true, draftEmpty: false), .running)
    }

    func testRunningDominatesTyping() {
        XCTAssertEqual(MascotState.classify(isRunning: true, isAlternateScreen: false, draftEmpty: false), .running)
    }
}
