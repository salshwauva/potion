import XCTest
@testable import PotionCore

final class ShellIntegrationScannerTests: XCTestCase {
    private func bytes(_ string: String) -> ArraySlice<UInt8> {
        Array(string.utf8)[...]
    }

    private func osc(_ payload: String) -> String {
        "\u{1b}]\(payload)\u{07}"
    }

    func testPromptAndInputMarkers() {
        let scanner = ShellIntegrationScanner()
        let events = scanner.feed(bytes(osc("133;A") + osc("133;B")))
        XCTAssertEqual(events, [.promptStart, .inputStart])
    }

    func testCommandLifecycleWithExitCode() {
        let scanner = ShellIntegrationScanner()
        let cmd = Data("ls -la".utf8).base64EncodedString()
        let stream = osc("133;C") + osc("9001;\(cmd)") + "total 0\n" + osc("133;D;0")
        let events = scanner.feed(bytes(stream))
        XCTAssertEqual(events, [
            .execStart,
            .commandText("ls -la"),
            .commandFinished(exitCode: 0, output: "total 0\n"),
        ])
    }

    func testNonZeroExitCode() {
        let scanner = ShellIntegrationScanner()
        let stream = osc("133;C") + "boom\n" + osc("133;D;127")
        let events = scanner.feed(bytes(stream))
        XCTAssertEqual(events, [.execStart, .commandFinished(exitCode: 127, output: "boom\n")])
    }

    func testOutputCapturedOnlyBetweenExecAndFinish() {
        let scanner = ShellIntegrationScanner()
        let stream = "prompt$ " + osc("133;C") + "captured" + osc("133;D;0") + "next prompt$ "
        let events = scanner.feed(bytes(stream))
        XCTAssertEqual(events, [.execStart, .commandFinished(exitCode: 0, output: "captured")])
    }

    func testEscapeSequencesStrippedFromCapturedOutput() {
        let scanner = ShellIntegrationScanner()
        // Red "ERR" via SGR, then reset, inside the captured region.
        let colored = "\u{1b}[31mERR\u{1b}[0m done"
        let stream = osc("133;C") + colored + osc("133;D;1")
        let events = scanner.feed(bytes(stream))
        XCTAssertEqual(events, [.execStart, .commandFinished(exitCode: 1, output: "ERR done")])
    }

    func testMarkerSplitAcrossFeeds() {
        let scanner = ShellIntegrationScanner()
        // Split an OSC 133;C right in the middle of the sequence.
        let whole = osc("133;C") + "out" + osc("133;D;0")
        let all = Array(whole.utf8)
        let cut = 3
        var events = scanner.feed(all[0..<cut][...])
        events += scanner.feed(all[cut...][...])
        XCTAssertEqual(events, [.execStart, .commandFinished(exitCode: 0, output: "out")])
    }

    func testStTerminatorEscBackslash() {
        let scanner = ShellIntegrationScanner()
        let stream = "\u{1b}]133;A\u{1b}\\"
        let events = scanner.feed(bytes(stream))
        XCTAssertEqual(events, [.promptStart])
    }

    func testAlternateScreenEnterExit() {
        let scanner = ShellIntegrationScanner()
        let enter = "\u{1b}[?1049h"
        let exit = "\u{1b}[?1049l"
        var events = scanner.feed(bytes(enter))
        XCTAssertEqual(events, [.enterAlternateScreen])
        XCTAssertTrue(scanner.isAlternateScreen)
        events = scanner.feed(bytes(exit))
        XCTAssertEqual(events, [.exitAlternateScreen])
        XCTAssertFalse(scanner.isAlternateScreen)
    }

    func testAlternateScreenIsIdempotent() {
        let scanner = ShellIntegrationScanner()
        _ = scanner.feed(bytes("\u{1b}[?1049h"))
        let again = scanner.feed(bytes("\u{1b}[?1049h"))
        XCTAssertTrue(again.isEmpty)
    }

    func testCaptureIsBounded() {
        let scanner = ShellIntegrationScanner(maxCaptureBytes: 16)
        let big = String(repeating: "x", count: 1000)
        let stream = osc("133;C") + big + osc("133;D;0")
        let events = scanner.feed(bytes(stream))
        guard case .commandFinished(_, let output) = events.last else {
            return XCTFail("expected commandFinished")
        }
        XCTAssertEqual(output.count, 16)
    }

    func testUnrelatedOscIgnored() {
        let scanner = ShellIntegrationScanner()
        // OSC 0 sets the window title and must not produce events.
        let events = scanner.feed(bytes("\u{1b}]0;my title\u{07}"))
        XCTAssertTrue(events.isEmpty)
    }
}
