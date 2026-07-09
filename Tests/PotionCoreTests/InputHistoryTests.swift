import XCTest
@testable import PotionCore

final class InputHistoryTests: XCTestCase {
    func testPreviousWalksBackwardThroughEntries() {
        var history = InputHistory()
        history.setEntries(["one", "two", "three"])
        XCTAssertEqual(history.previous(currentDraft: ""), "three")
        XCTAssertEqual(history.previous(currentDraft: ""), "two")
        XCTAssertEqual(history.previous(currentDraft: ""), "one")
        XCTAssertNil(history.previous(currentDraft: ""))
    }

    func testNextReturnsTowardDraft() {
        var history = InputHistory()
        history.setEntries(["one", "two"])
        _ = history.previous(currentDraft: "wip")
        _ = history.previous(currentDraft: "wip")
        XCTAssertEqual(history.next(currentDraft: ""), "two")
        XCTAssertEqual(history.next(currentDraft: ""), "wip")
        XCTAssertFalse(history.isBrowsing)
    }

    func testDraftPreservedAcrossBrowsing() {
        var history = InputHistory()
        history.setEntries(["cmd"])
        XCTAssertEqual(history.previous(currentDraft: "half typed"), "cmd")
        XCTAssertEqual(history.next(currentDraft: ""), "half typed")
    }

    func testConsecutiveDuplicatesAndBlanksDropped() {
        var history = InputHistory()
        history.setEntries(["ls", "ls", "  ", "cd"])
        XCTAssertEqual(history.previous(currentDraft: ""), "cd")
        XCTAssertEqual(history.previous(currentDraft: ""), "ls")
        XCTAssertNil(history.previous(currentDraft: ""))
    }

    func testNextWithoutBrowsingReturnsNil() {
        var history = InputHistory()
        history.setEntries(["a"])
        XCTAssertNil(history.next(currentDraft: "x"))
    }

    func testEmptyHistoryHasNothingToRecall() {
        var history = InputHistory()
        XCTAssertNil(history.previous(currentDraft: "draft"))
    }
}
