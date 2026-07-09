import Foundation

/// A parsed tldr documentation page: a one-line description and a list of
/// example invocations.
public struct TldrPage: Equatable {
    public var name: String
    public var description: String
    public var examples: [TldrExample]

    public init(name: String, description: String, examples: [TldrExample]) {
        self.name = name
        self.description = description
        self.examples = examples
    }
}

public struct TldrExample: Equatable {
    /// What the example does, in plain words.
    public var description: String
    /// The command to run, with tldr placeholders unwrapped.
    public var command: String

    public init(description: String, command: String) {
        self.description = description
        self.command = command
    }
}

/// Parses the tldr-pages markdown format into a ``TldrPage``.
///
/// The format is: a `#` title, one or more `>` description lines (with
/// `More information` and `See also` lines treated as metadata), then example
/// blocks of a `-` description line followed by a backtick-wrapped command.
public enum TldrParser {
    public static func parse(_ markdown: String, name: String) -> TldrPage {
        var descriptionLines: [String] = []
        var examples: [TldrExample] = []
        var pendingDescription: String?

        for rawLine in markdown.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            if line.hasPrefix("#") {
                continue
            }

            if line.hasPrefix(">") {
                let text = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
                if text.hasPrefix("More information") || text.hasPrefix("See also") { continue }
                descriptionLines.append(text)
                continue
            }

            if line.hasPrefix("- ") {
                var text = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if text.hasSuffix(":") { text = String(text.dropLast()) }
                pendingDescription = text
                continue
            }

            if line.hasPrefix("`"), line.hasSuffix("`"), line.count >= 2 {
                let command = unwrapPlaceholders(String(line.dropFirst().dropLast()))
                if let description = pendingDescription {
                    examples.append(TldrExample(description: description, command: command))
                    pendingDescription = nil
                }
                continue
            }
        }

        return TldrPage(
            name: name,
            description: descriptionLines.joined(separator: " "),
            examples: examples
        )
    }

    /// Removes tldr `{{ }}` placeholder braces, leaving readable example text.
    static func unwrapPlaceholders(_ command: String) -> String {
        command
            .replacingOccurrences(of: "{{", with: "")
            .replacingOccurrences(of: "}}", with: "")
    }
}
