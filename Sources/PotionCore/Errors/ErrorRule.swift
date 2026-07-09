import Foundation

/// A data-driven error rule. A rule matches when every specified matcher matches
/// the failed command. Its explanation and fix commands may contain `{command}`,
/// `{exit}`, and `{1}`, `{2}` (regex capture group) placeholders.
public struct ErrorRule: Codable, Equatable {
    public var id: String
    /// The command's first word must be one of these, if given.
    public var commandPrefix: [String]?
    /// A regular expression searched in the captured output, if given.
    public var outputRegex: String?
    /// The exit code must equal this, if given.
    public var exitCode: Int32?
    public var title: String
    public var explanation: String
    public var fixes: [ErrorFixTemplate]

    enum CodingKeys: String, CodingKey {
        case id, commandPrefix, outputRegex, exitCode, title, explanation, fixes
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        commandPrefix = try c.decodeIfPresent([String].self, forKey: .commandPrefix)
        outputRegex = try c.decodeIfPresent(String.self, forKey: .outputRegex)
        exitCode = try c.decodeIfPresent(Int32.self, forKey: .exitCode)
        title = try c.decode(String.self, forKey: .title)
        explanation = try c.decode(String.self, forKey: .explanation)
        fixes = try c.decodeIfPresent([ErrorFixTemplate].self, forKey: .fixes) ?? []
    }

    public init(id: String, commandPrefix: [String]? = nil, outputRegex: String? = nil, exitCode: Int32? = nil, title: String, explanation: String, fixes: [ErrorFixTemplate] = []) {
        self.id = id
        self.commandPrefix = commandPrefix
        self.outputRegex = outputRegex
        self.exitCode = exitCode
        self.title = title
        self.explanation = explanation
        self.fixes = fixes
    }
}

public struct ErrorFixTemplate: Codable, Equatable {
    public var description: String
    public var command: String

    public init(description: String, command: String) {
        self.description = description
        self.command = command
    }
}

public struct ErrorRuleSet: Codable, Equatable {
    public var rules: [ErrorRule]
    public init(rules: [ErrorRule]) { self.rules = rules }
}
