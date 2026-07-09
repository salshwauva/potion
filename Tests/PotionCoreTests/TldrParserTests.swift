import XCTest
@testable import PotionCore

final class TldrParserTests: XCTestCase {
    private let sample = """
    # grep

    > Find patterns in files using regexes.
    > See also: rg.
    > More information: <https://example.com>.

    - Search for a pattern within a file:

    `grep "{{search_pattern}}" {{path/to/file}}`

    - Search recursively:

    `grep {{[-r|--recursive]}} "{{pattern}}" {{path/to/directory}}`
    """

    func testParsesDescriptionWithoutMetadata() {
        let page = TldrParser.parse(sample, name: "grep")
        XCTAssertEqual(page.description, "Find patterns in files using regexes.")
    }

    func testParsesExamples() {
        let page = TldrParser.parse(sample, name: "grep")
        XCTAssertEqual(page.examples.count, 2)
        XCTAssertEqual(page.examples[0].description, "Search for a pattern within a file")
        XCTAssertEqual(page.examples[0].command, "grep \"search_pattern\" path/to/file")
    }

    func testPlaceholdersUnwrapped() {
        let page = TldrParser.parse(sample, name: "grep")
        XCTAssertFalse(page.examples[1].command.contains("{{"))
        XCTAssertFalse(page.examples[1].command.contains("}}"))
        XCTAssertTrue(page.examples[1].command.contains("[-r|--recursive]"))
    }

    func testHandlesPageWithNoExamples() {
        let page = TldrParser.parse("# foo\n\n> Does a thing.\n", name: "foo")
        XCTAssertEqual(page.description, "Does a thing.")
        XCTAssertTrue(page.examples.isEmpty)
    }

    func testBundledGrepPageParses() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/tldr/common/grep.md")
        let markdown = try String(contentsOf: url, encoding: .utf8)
        let page = TldrParser.parse(markdown, name: "grep")
        XCTAssertFalse(page.description.isEmpty)
        XCTAssertGreaterThan(page.examples.count, 2)
        XCTAssertFalse(page.description.contains("More information"))
    }
}
