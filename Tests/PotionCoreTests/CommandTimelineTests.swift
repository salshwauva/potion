import XCTest
@testable import PotionCore

final class CommandTimelineTests: XCTestCase {
    private func fixedClock(_ times: [TimeInterval]) -> () -> Date {
        var index = 0
        return {
            defer { index += 1 }
            let value = times[min(index, times.count - 1)]
            return Date(timeIntervalSince1970: value)
        }
    }

    func testSuccessfulCommandRecord() {
        let timeline = CommandTimeline(now: fixedClock([100, 102]))
        timeline.setCwd("/Users/sophia")
        timeline.apply(.execStart)
        timeline.apply(.commandText("ls"))
        timeline.apply(.commandFinished(exitCode: 0, output: "a\nb\n"))

        XCTAssertEqual(timeline.records.count, 1)
        let record = timeline.records[0]
        XCTAssertEqual(record.command, "ls")
        XCTAssertEqual(record.exitCode, 0)
        XCTAssertEqual(record.status, .success)
        XCTAssertEqual(record.cwd, "/Users/sophia")
        XCTAssertEqual(record.capturedOutput, "a\nb\n")
        XCTAssertEqual(record.duration, 2)
    }

    func testFailedCommandIsMarkedFailure() {
        let timeline = CommandTimeline(now: fixedClock([0, 1]))
        timeline.apply(.execStart)
        timeline.apply(.commandText("false"))
        timeline.apply(.commandFinished(exitCode: 1, output: ""))
        XCTAssertEqual(timeline.records[0].status, .failure)
    }

    func testRunningCommandHasNoExit() {
        let timeline = CommandTimeline(now: fixedClock([0]))
        timeline.apply(.execStart)
        timeline.apply(.commandText("sleep 10"))
        XCTAssertEqual(timeline.records[0].status, .running)
        XCTAssertNil(timeline.records[0].exitCode)
        XCTAssertNil(timeline.records[0].duration)
    }

    func testMultipleCommandsAccumulate() {
        let timeline = CommandTimeline(now: fixedClock([0, 1, 2, 3]))
        timeline.apply(.execStart)
        timeline.apply(.commandText("one"))
        timeline.apply(.commandFinished(exitCode: 0, output: ""))
        timeline.apply(.execStart)
        timeline.apply(.commandText("two"))
        timeline.apply(.commandFinished(exitCode: 0, output: ""))
        XCTAssertEqual(timeline.records.map(\.command), ["one", "two"])
    }

    func testCwdStampedPerCommand() {
        let timeline = CommandTimeline(now: fixedClock([0, 1, 2, 3]))
        timeline.setCwd("/a")
        timeline.apply(.execStart)
        timeline.apply(.commandFinished(exitCode: 0, output: ""))
        timeline.setCwd("/b")
        timeline.apply(.execStart)
        timeline.apply(.commandFinished(exitCode: 0, output: ""))
        XCTAssertEqual(timeline.records.map(\.cwd), ["/a", "/b"])
    }

    func testAlternateScreenTracked() {
        let timeline = CommandTimeline(now: fixedClock([0]))
        timeline.apply(.enterAlternateScreen)
        XCTAssertTrue(timeline.isAlternateScreen)
        timeline.apply(.exitAlternateScreen)
        XCTAssertFalse(timeline.isAlternateScreen)
    }

    func testFinishWithoutActiveCommandIsIgnored() {
        let timeline = CommandTimeline(now: fixedClock([0]))
        timeline.apply(.commandFinished(exitCode: 0, output: "x"))
        XCTAssertTrue(timeline.records.isEmpty)
    }
}
