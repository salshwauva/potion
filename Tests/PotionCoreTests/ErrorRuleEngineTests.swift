import XCTest
@testable import PotionCore

final class ErrorRuleEngineTests: XCTestCase {
    private func bundledEngine(brew: [String] = []) throws -> ErrorRuleEngine {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/data/rules.json")
        let set = try JSONDecoder().decode(ErrorRuleSet.self, from: Data(contentsOf: url))
        return ErrorRuleEngine(rules: set.rules, brewFormulae: brew)
    }

    func testSuccessProducesNoCard() throws {
        let engine = try bundledEngine()
        XCTAssertNil(engine.explain(command: "ls", exitCode: 0, output: "", knownCommands: []))
    }

    func testCommandNotFoundTypoSuggestion() throws {
        let engine = try bundledEngine()
        let card = engine.explain(
            command: "gti status",
            exitCode: 127,
            output: "zsh: command not found: gti",
            knownCommands: ["git", "ls", "cat"]
        )
        XCTAssertEqual(card?.title, "Command not found: gti")
        XCTAssertEqual(card?.fixes.first?.command, "git status")
        XCTAssertTrue(card?.fixes.first?.description.contains("Did you mean git") ?? false)
    }

    func testCommandNotFoundHomebrewHint() throws {
        let engine = try bundledEngine(brew: ["wget"])
        let card = engine.explain(
            command: "wget https://example.com",
            exitCode: 127,
            output: "zsh: command not found: wget",
            knownCommands: []
        )
        XCTAssertTrue(card?.fixes.contains { $0.command == "brew install wget" } ?? false)
    }

    func testPermissionDeniedSuggestsSudo() throws {
        let engine = try bundledEngine()
        let card = engine.explain(
            command: "rm /etc/hosts",
            exitCode: 1,
            output: "rm: /etc/hosts: Permission denied",
            knownCommands: []
        )
        XCTAssertEqual(card?.title, "Permission denied")
        XCTAssertEqual(card?.fixes.first?.command, "sudo rm /etc/hosts")
    }

    func testNoSuchFileSuggestsLs() throws {
        let engine = try bundledEngine()
        let card = engine.explain(
            command: "cat missing.txt",
            exitCode: 1,
            output: "cat: missing.txt: No such file or directory",
            knownCommands: []
        )
        XCTAssertEqual(card?.title, "No such file or directory")
        XCTAssertEqual(card?.fixes.first?.command, "ls")
    }

    func testGitNotARepoOnlyForGit() throws {
        let engine = try bundledEngine()
        let output = "fatal: not a git repository (or any of the parent directories): .git"
        let gitCard = engine.explain(command: "git status", exitCode: 128, output: output, knownCommands: [])
        XCTAssertEqual(gitCard?.fixes.first?.command, "git init")

        // The same output text under a non-git command must not match the git rule.
        let otherCard = engine.explain(command: "echo not a git repository", exitCode: 1, output: "not a git repository", knownCommands: [])
        XCTAssertNotEqual(otherCard?.title, "This folder is not a git repository")
    }

    func testPortInUseExtractsPort() throws {
        let engine = try bundledEngine()
        let card = engine.explain(
            command: "npm start",
            exitCode: 1,
            output: "Error: listen EADDRINUSE: address already in use :::3000",
            knownCommands: []
        )
        XCTAssertEqual(card?.title, "That port is already in use")
        XCTAssertEqual(card?.fixes.first?.command, "lsof -i :3000")
    }

    func testGitPushRejected() throws {
        let engine = try bundledEngine()
        let card = engine.explain(
            command: "git push",
            exitCode: 1,
            output: "! [rejected] main -> main (non-fast-forward)",
            knownCommands: []
        )
        XCTAssertEqual(card?.title, "The push was rejected")
        XCTAssertEqual(card?.fixes.map(\.command), ["git pull --rebase", "git push"])
    }

    func testGenericFallbackForUnknownFailure() throws {
        let engine = try bundledEngine()
        let card = engine.explain(command: "somebinary", exitCode: 3, output: "weird internal error", knownCommands: [])
        XCTAssertEqual(card?.title, "That command reported a problem")
        XCTAssertTrue(card?.explanation.contains("code 3") ?? false)
    }

    func testEveryFailureGetsACard() throws {
        let engine = try bundledEngine()
        XCTAssertNotNil(engine.explain(command: "anything", exitCode: 1, output: "", knownCommands: []))
    }
}
