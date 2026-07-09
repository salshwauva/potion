import Foundation

/// Plain-English phrases for shell syntax that no command spec describes:
/// operators, redirections, and special tokens. Kept as data so the wording is
/// reviewable and testable in one place. Redirect and special phrases may
/// contain `{file}` or `{name}` placeholders filled in by the renderer.
public struct SyntaxTable: Codable, Equatable {
    /// Control operators that join commands, keyed by operator text.
    public var operators: [String: String]
    /// Redirections, keyed by operator text. Values use `{file}`.
    public var redirects: [String: String]
    /// Named phrases for special tokens and fallbacks.
    public var specials: [String: String]

    public init(operators: [String: String], redirects: [String: String], specials: [String: String]) {
        self.operators = operators
        self.redirects = redirects
        self.specials = specials
    }

    public func special(_ key: String, fallback: String) -> String {
        specials[key] ?? fallback
    }

    /// A minimal built-in table so the renderer still works if the bundled JSON
    /// fails to load.
    public static let builtin = SyntaxTable(
        operators: [
            "|": "then feed that into the next command",
            "|&": "then feed that output and its errors into the next command",
            "||": "otherwise, if that failed, run",
            "&&": "then, only if that succeeded, run",
            ";": "then, regardless, run",
            "&": "in the background",
        ],
        redirects: [
            ">": "write the output to {file}, replacing it",
            ">>": "add the output to the end of {file}",
            "<": "read input from {file}",
            "2>": "write error messages to {file}",
            "2>>": "add error messages to the end of {file}",
        ],
        specials: [
            "home": "your home folder",
            "sudo": "as an administrator (be careful)",
            "variable": "the value of {name}",
            "glob": "a pattern that matches files",
            "unknown_flag": "not sure what this flag does",
            "run_program": "run the program {name}",
        ]
    )
}
