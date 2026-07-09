import Foundation

/// Turns a failed command into an ``ErrorCard``. Most rules are data (matcher to
/// explanation to fix templates). Command-not-found is handled in code because
/// it needs an edit-distance typo check against the known commands and a lookup
/// in the bundled Homebrew formula list.
public final class ErrorRuleEngine {
    private let rules: [ErrorRule]
    private let brewFormulae: Set<String>

    public init(rules: [ErrorRule], brewFormulae: [String] = []) {
        self.rules = rules
        self.brewFormulae = Set(brewFormulae)
    }

    /// Produces a card for a nonzero exit, or nil for success. `knownCommands`
    /// are executables on PATH, used for typo suggestions.
    public func explain(command: String, exitCode: Int32, output: String, knownCommands: [String] = []) -> ErrorCard? {
        guard exitCode != 0 else { return nil }

        if let card = commandNotFoundCard(command: command, output: output, knownCommands: knownCommands) {
            return card
        }

        let firstWord = Tokenizer.tokenize(command).first(where: { $0.kind == .word })?.value ?? ""
        for rule in rules {
            guard matches(rule, command: command, firstWord: firstWord, exitCode: exitCode, output: output) else { continue }
            let groups = rule.outputRegex.flatMap { captureGroups(pattern: $0, in: output) } ?? []
            return ErrorCard(
                title: rule.title,
                explanation: substitute(rule.explanation, command: command, exitCode: exitCode, groups: groups),
                fixes: rule.fixes.map { fix in
                    ErrorFix(
                        description: fix.description,
                        command: substitute(fix.command, command: command, exitCode: exitCode, groups: groups)
                    )
                }
            )
        }

        return genericFallback(command: command, exitCode: exitCode)
    }

    // MARK: Command not found

    private func commandNotFoundCard(command: String, output: String, knownCommands: [String]) -> ErrorCard? {
        // zsh: "zsh: command not found: foo"  bash: "foo: command not found"
        let patterns = [
            "command not found: (\\S+)",
            "(\\S+): command not found",
        ]
        var missing: String?
        for pattern in patterns {
            if let groups = captureGroups(pattern: pattern, in: output), groups.count > 1 {
                missing = groups[1]
                break
            }
        }
        guard let missing else { return nil }

        var fixes: [ErrorFix] = []

        if let suggestion = closestMatch(to: missing, in: knownCommands) {
            let corrected = replaceFirstWord(in: command, with: suggestion)
            fixes.append(ErrorFix(description: "Did you mean \(suggestion)?", command: corrected))
        }

        if brewFormulae.contains(missing) {
            fixes.append(ErrorFix(description: "Install it with Homebrew", command: "brew install \(missing)"))
        }

        return ErrorCard(
            title: "Command not found: \(missing)",
            explanation: "The shell could not find a program called \(missing). It may be misspelled, or it may not be installed on this machine.",
            fixes: fixes
        )
    }

    // MARK: Matching

    private func matches(_ rule: ErrorRule, command: String, firstWord: String, exitCode: Int32, output: String) -> Bool {
        if let prefixes = rule.commandPrefix, !prefixes.contains(firstWord) {
            return false
        }
        if let code = rule.exitCode, code != exitCode {
            return false
        }
        if let pattern = rule.outputRegex, captureGroups(pattern: pattern, in: output) == nil {
            return false
        }
        // A rule with no matchers at all never fires; that is what the fallback is for.
        return rule.commandPrefix != nil || rule.exitCode != nil || rule.outputRegex != nil
    }

    // MARK: Generic fallback

    private func genericFallback(command: String, exitCode: Int32) -> ErrorCard {
        ErrorCard(
            title: "That command reported a problem",
            explanation: "\(exitMeaning(exitCode)) The lines above show what the program printed, which usually explains what went wrong.",
            fixes: []
        )
    }

    private func exitMeaning(_ code: Int32) -> String {
        switch code {
        case 1: return "The command exited with a general error (code 1)."
        case 2: return "The command was used incorrectly (code 2), often a bad option or missing argument."
        case 126: return "The file was found but is not executable (code 126)."
        case 127: return "The command was not found (code 127)."
        case 130: return "The command was stopped with Control-C (code 130)."
        case 137: return "The command was force-stopped (code 137)."
        case 139: return "The command crashed with a segmentation fault (code 139)."
        default: return "The command exited with code \(code)."
        }
    }

    // MARK: Helpers

    /// Returns the match and its capture groups, or nil when the pattern does not
    /// match. Index 0 is the whole match; 1 and up are groups.
    private func captureGroups(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        var groups: [String] = []
        for i in 0..<match.numberOfRanges {
            if let r = Range(match.range(at: i), in: text) {
                groups.append(String(text[r]))
            } else {
                groups.append("")
            }
        }
        return groups
    }

    private func substitute(_ template: String, command: String, exitCode: Int32, groups: [String]) -> String {
        var result = template.replacingOccurrences(of: "{command}", with: command)
        result = result.replacingOccurrences(of: "{exit}", with: String(exitCode))
        for (index, value) in groups.enumerated() {
            result = result.replacingOccurrences(of: "{\(index)}", with: value)
        }
        return result
    }

    private func replaceFirstWord(in command: String, with replacement: String) -> String {
        guard let first = Tokenizer.tokenize(command).first(where: { $0.kind == .word }) else { return replacement }
        var chars = Array(command)
        chars.replaceSubrange(first.start..<first.end, with: Array(replacement))
        return String(chars)
    }

    /// Closest command within a small edit distance, for typo suggestions.
    private func closestMatch(to word: String, in candidates: [String]) -> String? {
        var best: String?
        var bestDistance = Int.max
        let threshold = word.count <= 4 ? 1 : 2
        for candidate in candidates where abs(candidate.count - word.count) <= threshold {
            let distance = editDistance(word, candidate)
            if distance < bestDistance && distance <= threshold && candidate != word {
                bestDistance = distance
                best = candidate
            }
        }
        return best
    }

    /// Damerau-Levenshtein (optimal string alignment) distance. Counts an
    /// adjacent transposition as a single edit, since swapped letters are the
    /// most common typo (for example "gti" for "git").
    private func editDistance(_ a: String, _ b: String) -> Int {
        let x = Array(a), y = Array(b)
        let m = x.count, n = y.count
        if m == 0 { return n }
        if n == 0 { return m }

        var d = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        for i in 0...m { d[i][0] = i }
        for j in 0...n { d[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = x[i - 1] == y[j - 1] ? 0 : 1
                d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
                if i > 1, j > 1, x[i - 1] == y[j - 2], x[i - 2] == y[j - 1] {
                    d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1)
                }
            }
        }
        return d[m][n]
    }
}
