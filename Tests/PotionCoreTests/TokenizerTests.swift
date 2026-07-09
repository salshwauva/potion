import XCTest
@testable import PotionCore

final class TokenizerTests: XCTestCase {
    func testSimpleWords() {
        let tokens = Tokenizer.tokenize("git status")
        XCTAssertEqual(tokens.map(\.value), ["git", "status"])
        XCTAssertEqual(tokens.map(\.kind), [.word, .word])
        XCTAssertEqual(tokens[0].start, 0)
        XCTAssertEqual(tokens[1].start, 4)
    }

    func testDoubleQuotedStringIsOneToken() {
        let tokens = Tokenizer.tokenize("grep \"to do\" file")
        XCTAssertEqual(tokens.map(\.value), ["grep", "to do", "file"])
        XCTAssertTrue(tokens[1].wasQuoted)
    }

    func testSingleQuotesPreserveContent() {
        let tokens = Tokenizer.tokenize("echo 'a|b && c'")
        XCTAssertEqual(tokens.map(\.value), ["echo", "a|b && c"])
    }

    func testBackslashEscape() {
        let tokens = Tokenizer.tokenize("cat my\\ file.txt")
        XCTAssertEqual(tokens.map(\.value), ["cat", "my file.txt"])
    }

    func testPipeOperator() {
        let tokens = Tokenizer.tokenize("ls | wc -l")
        XCTAssertEqual(tokens.map(\.value), ["ls", "|", "wc", "-l"])
        XCTAssertEqual(tokens[1].kind, .op)
    }

    func testLogicalAndRedirect() {
        let tokens = Tokenizer.tokenize("make && ./run > out.txt")
        XCTAssertEqual(tokens.map(\.value), ["make", "&&", "./run", ">", "out.txt"])
        XCTAssertEqual(tokens[1].kind, .op)
        XCTAssertEqual(tokens[3].kind, .op)
    }

    func testStderrRedirect() {
        let tokens = Tokenizer.tokenize("cmd 2> err.log")
        XCTAssertEqual(tokens.map(\.value), ["cmd", "2>", "err.log"])
        XCTAssertEqual(tokens[1].kind, .op)
    }

    func testAppendRedirect() {
        let tokens = Tokenizer.tokenize("echo hi >> log")
        XCTAssertEqual(tokens.map(\.value), ["echo", "hi", ">>", "log"])
    }

    func testSegmentsSplitOnControlOperators() {
        let tokens = Tokenizer.tokenize("cat f | grep x && echo done")
        let segments = Tokenizer.segments(tokens)
        XCTAssertEqual(segments.count, 3)
        XCTAssertEqual(segments[0].tokens.map(\.value), ["cat", "f"])
        XCTAssertEqual(segments[0].terminator?.value, "|")
        XCTAssertEqual(segments[1].tokens.map(\.value), ["grep", "x"])
        XCTAssertEqual(segments[2].tokens.map(\.value), ["echo", "done"])
    }

    func testRangesRoundTrip() {
        let line = "grep -r \"todo\" src"
        let tokens = Tokenizer.tokenize(line)
        let chars = Array(line)
        for token in tokens {
            XCTAssertEqual(String(chars[token.start..<token.end]), token.raw)
        }
    }
}
