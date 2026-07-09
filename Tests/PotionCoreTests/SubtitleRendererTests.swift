import XCTest
@testable import PotionCore

final class SubtitleRendererTests: XCTestCase {
    private func makeRenderer() throws -> SubtitleRenderer {
        let specsURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/data/specs.json")
        let specs = try SpecStore.decode(Data(contentsOf: specsURL))
        return SubtitleRenderer(engine: SpecEngine(specs: specs), syntax: .builtin)
    }

    /// Golden corpus: command line to expected plain-English translation. The
    /// wording is the reviewable contract for the thesis feature.
    private let golden: [(String, String)] = [
        ("grep -r \"todo\" src | wc -l",
         "search for text inside files · search inside folders and their subfolders · the text or pattern to look for: \"todo\" · the path src · then feed that into the next command · count lines, words, and characters · count lines only"),
        ("git status", "show which files changed since the last commit"),
        ("git", "the version control system"),
        ("git checkout main", "switch branches or restore files · the branch or path to switch to: main"),
        ("git checkout -b feature", "switch branches or restore files · create a new branch and switch to it: feature"),
        ("git commit -m \"fix login\"", "save the staged changes as a new commit · set the commit message: \"fix login\""),
        ("git commit --amend", "save the staged changes as a new commit · replace the previous commit"),
        ("git commit --message=hi", "save the staged changes as a new commit · set the commit message: hi"),
        ("git log --oneline", "show the commit history · one line per commit"),
        ("git push -u", "send local commits to a remote · remember the remote branch for next time"),
        ("git add .", "stage changes to include in the next commit · the path ."),
        ("ls -la", "list the contents of a folder · long format, one file per line with details · include hidden files"),
        ("ls -l ~", "list the contents of a folder · long format, one file per line with details · your home folder"),
        ("ls *.txt", "list the contents of a folder · the path *.txt (a pattern that matches files)"),
        ("ls --bogus", "list the contents of a folder · --bogus: not sure what this flag does"),
        ("ls -Z", "list the contents of a folder · -Z: not sure what this flag does"),
        ("rm -rf build", "delete files or folders · delete a folder and everything in it · do not ask for confirmation · the path build"),
        ("cat file.txt", "print the contents of a file · the path file.txt"),
        ("cat a.txt > out.txt", "print the contents of a file · the path a.txt · write the output to out.txt, replacing it"),
        ("cat < input.txt", "print the contents of a file · read input from input.txt"),
        ("echo hi >> log.txt", "print text back to the screen · the value hi · add the output to the end of log.txt"),
        ("echo hello", "print text back to the screen · the value hello"),
        ("echo $HOME", "print text back to the screen · the value of HOME"),
        ("mkdir -p a/b/c", "create a new folder · create any missing parent folders too · the value a/b/c"),
        ("cp -r src dest", "copy files or folders · copy a folder and its contents · the path src · the path dest"),
        ("chmod 755 script.sh", "change who can read, write, or run a file · the permission setting, for example 755: 755 · the path script.sh"),
        ("wc -l file.txt", "count lines, words, and characters · count lines only · the path file.txt"),
        ("head -n 20 log", "show the first lines of a file · how many lines to show: 20 · the path log"),
        ("grep -i -n pattern file.txt", "search for text inside files · ignore capitalization · show the line number of each match · the text or pattern to look for: pattern · the path file.txt"),
        ("grep -rin foo .", "search for text inside files · search inside folders and their subfolders · ignore capitalization · show the line number of each match · the text or pattern to look for: foo · the path ."),
        ("tar -xzf archive.tar.gz", "bundle files into an archive or unpack one · unpack an existing archive · compress or read with gzip · use this archive file · the path archive.tar.gz"),
        ("cd ~", "change the current folder · your home folder"),
        ("cd Documents", "change the current folder · the folder Documents"),
        ("npm install", "install dependencies"),
        ("npm run build", "run a script defined in package.json · the value build"),
        ("brew install wget", "install a formula or app · the value wget"),
        ("unknowncmd --weird", "run the program unknowncmd · --weird: not sure what this flag does"),
        ("make 2> errors.log", "run the program make · write error messages to errors.log"),
        ("cat a && cat b", "print the contents of a file · the path a · then, only if that succeeded, run · print the contents of a file · the path b"),
        ("false || echo failed", "run the program false · otherwise, if that failed, run · print text back to the screen · the value failed"),
        ("ls; pwd", "list the contents of a folder · then, regardless, run · run the program pwd"),
        ("sleep 5 &", "run the program sleep · the value 5 · in the background"),
        ("sudo rm -rf /tmp/x", "as an administrator (be careful) · delete files or folders · delete a folder and everything in it · do not ask for confirmation · the path /tmp/x"),
    ]

    func testGoldenCorpus() throws {
        let renderer = try makeRenderer()
        for (input, expected) in golden {
            let actual = renderer.render(input).plainText
            XCTAssertEqual(actual, expected, "for input: \(input)")
        }
    }

    func testGoldenCorpusHasAtLeastFortyCases() {
        XCTAssertGreaterThanOrEqual(golden.count, 40)
    }

    func testEmptyLineHasNoSubtitle() throws {
        let renderer = try makeRenderer()
        XCTAssertTrue(renderer.render("").isEmpty)
        XCTAssertTrue(renderer.render("    ").isEmpty)
    }

    func testUnknownFlagMarkedUnknown() throws {
        let renderer = try makeRenderer()
        let subtitle = renderer.render("ls -Z")
        XCTAssertEqual(subtitle.phrases.last?.confidence, .unknown)
    }

    func testKnownPhraseMarkedKnown() throws {
        let renderer = try makeRenderer()
        let subtitle = renderer.render("ls -l")
        XCTAssertTrue(subtitle.phrases.allSatisfy { $0.confidence == .known })
    }

    func testBundledSyntaxJSONMatchesBuiltin() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/data/syntax.json")
        let table = try JSONDecoder().decode(SyntaxTable.self, from: Data(contentsOf: url))
        XCTAssertEqual(table, .builtin)
    }
}
