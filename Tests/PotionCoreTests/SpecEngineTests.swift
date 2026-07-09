import XCTest
@testable import PotionCore

private struct StubFiles: FileLister {
    let byDirectory: [String: [FileEntry]]
    func entries(inDirectory path: String) -> [FileEntry] {
        byDirectory[path] ?? byDirectory["*"] ?? []
    }
}

final class SpecEngineTests: XCTestCase {
    private func engine() -> SpecEngine {
        let git = CommandSpec(
            names: ["git"],
            description: "The version control system",
            subcommands: [
                CommandSpec(names: ["checkout"], description: "Switch branches"),
                CommandSpec(names: ["cherry-pick"], description: "Apply one commit"),
                CommandSpec(names: ["commit"], description: "Save staged changes",
                    options: [OptionSpec(names: ["-m", "--message"], description: "Set the message")]),
                CommandSpec(names: ["status"], description: "Show changes"),
            ]
        )
        let tar = CommandSpec(
            names: ["tar"],
            description: "Archive files",
            options: [
                OptionSpec(names: ["-c", "--create"], description: "Create an archive"),
                OptionSpec(names: ["-x", "--extract"], description: "Unpack an archive"),
                OptionSpec(names: ["-f", "--file"], description: "Use this file"),
            ]
        )
        let cat = CommandSpec(
            names: ["cat"],
            description: "Print a file",
            args: [ArgSpec(name: "file", template: .filepaths, isVariadic: true)]
        )
        return SpecEngine(specs: [git, tar, cat])
    }

    private let noFiles = StubFiles(byDirectory: [:])

    func testSubcommandCompletion() {
        let line = "git ch"
        let result = engine().complete(line: line, cursor: line.count, cwd: "/", files: noFiles)
        let names = result.completions.map(\.insertion)
        XCTAssertTrue(names.contains("checkout"))
        XCTAssertTrue(names.contains("cherry-pick"))
        XCTAssertFalse(names.contains("status"))
        let checkout = result.completions.first { $0.insertion == "checkout" }
        XCTAssertEqual(checkout?.description, "Switch branches")
        XCTAssertEqual(result.replaceStart, 4)
        XCTAssertEqual(result.replaceEnd, 6)
    }

    func testOptionCompletionListsFlags() {
        let line = "tar -"
        let result = engine().complete(line: line, cursor: line.count, cwd: "/", files: noFiles)
        let names = result.completions.map(\.insertion)
        XCTAssertTrue(names.contains("-c"))
        XCTAssertTrue(names.contains("--create"))
        XCTAssertTrue(names.contains("-x"))
        let create = result.completions.first { $0.insertion == "-c" }
        XCTAssertEqual(create?.description, "Create an archive")
    }

    func testCommandNameCompletion() {
        let line = "gi"
        let result = engine().complete(line: line, cursor: line.count, cwd: "/", files: noFiles)
        XCTAssertEqual(result.completions.map(\.insertion), ["git"])
        XCTAssertEqual(result.completions.first?.kind, .command)
    }

    func testOptionWithinSubcommand() {
        let line = "git commit --m"
        let result = engine().complete(line: line, cursor: line.count, cwd: "/", files: noFiles)
        XCTAssertTrue(result.completions.map(\.insertion).contains("--message"))
    }

    func testPathCompletionRelativeToCwd() {
        let files = StubFiles(byDirectory: [
            "/work/project": [
                FileEntry(name: "README.md", isDirectory: false),
                FileEntry(name: "src", isDirectory: true),
                FileEntry(name: "run.sh", isDirectory: false),
            ]
        ])
        let line = "cat r"
        let result = engine().complete(line: line, cursor: line.count, cwd: "/work/project", files: files)
        let insertions = result.completions.map(\.insertion)
        XCTAssertTrue(insertions.contains("README.md"))
        XCTAssertTrue(insertions.contains("run.sh"))
        XCTAssertFalse(insertions.contains("src/"))
    }

    func testPathCompletionIntoSubdirectory() {
        let files = StubFiles(byDirectory: [
            "/work/src": [
                FileEntry(name: "main.swift", isDirectory: false),
                FileEntry(name: "models", isDirectory: true),
            ]
        ])
        let line = "cat src/m"
        let result = engine().complete(line: line, cursor: line.count, cwd: "/work", files: files)
        let insertions = result.completions.map(\.insertion)
        XCTAssertTrue(insertions.contains("src/main.swift"))
        XCTAssertTrue(insertions.contains("src/models/"))
    }

    func testFoldersOnlyTemplate() {
        let cd = CommandSpec(names: ["cd"], args: [ArgSpec(template: .folders)])
        let files = StubFiles(byDirectory: [
            "/w": [
                FileEntry(name: "docs", isDirectory: true),
                FileEntry(name: "notes.txt", isDirectory: false),
            ]
        ])
        let line = "cd "
        let result = SpecEngine(specs: [cd]).complete(line: line, cursor: line.count, cwd: "/w", files: files)
        let insertions = result.completions.map(\.insertion)
        XCTAssertTrue(insertions.contains("docs/"))
        XCTAssertFalse(insertions.contains("notes.txt"))
    }

    func testBundledSpecsDecodeAndComplete() throws {
        let specsURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // PotionCoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("Resources/data/specs.json")
        let data = try Data(contentsOf: specsURL)
        let specs = try SpecStore.decode(data)
        let engine = SpecEngine(specs: specs)

        let git = engine.complete(line: "git ch", cursor: 6, cwd: "/", files: noFiles)
        XCTAssertTrue(git.completions.contains { $0.insertion == "checkout" })

        let tar = engine.complete(line: "tar -", cursor: 5, cwd: "/", files: noFiles)
        let tarFlags = tar.completions.map(\.insertion)
        XCTAssertTrue(tarFlags.contains("--create"))
        XCTAssertTrue(tarFlags.contains("-x"))
    }

    func testLenientDecodingOfMinimalSpecJSON() throws {
        let json = """
        [{ "names": ["hello"], "description": "say hi" }]
        """
        let specs = try SpecStore.decode(Data(json.utf8))
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].name, "hello")
        XCTAssertTrue(specs[0].subcommands.isEmpty)
    }
}
