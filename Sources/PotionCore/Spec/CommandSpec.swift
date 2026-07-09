import Foundation

/// A completion specification for a command, mirroring the shape of the Fig
/// autocomplete specs: a command has subcommands, options, and positional
/// arguments, each carrying a human description. The same tree feeds both
/// autocomplete suggestions and subtitle translations.
public struct CommandSpec: Codable, Equatable {
    /// Command or subcommand names. The first is canonical; the rest are aliases.
    public var names: [String]
    public var description: String?
    public var subcommands: [CommandSpec]
    public var options: [OptionSpec]
    public var args: [ArgSpec]

    public init(
        names: [String],
        description: String? = nil,
        subcommands: [CommandSpec] = [],
        options: [OptionSpec] = [],
        args: [ArgSpec] = []
    ) {
        self.names = names
        self.description = description
        self.subcommands = subcommands
        self.options = options
        self.args = args
    }

    enum CodingKeys: String, CodingKey {
        case names, description, subcommands, options, args
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        names = try c.decode([String].self, forKey: .names)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        subcommands = try c.decodeIfPresent([CommandSpec].self, forKey: .subcommands) ?? []
        options = try c.decodeIfPresent([OptionSpec].self, forKey: .options) ?? []
        args = try c.decodeIfPresent([ArgSpec].self, forKey: .args) ?? []
    }

    public var name: String { names.first ?? "" }

    public func subcommand(named token: String) -> CommandSpec? {
        subcommands.first { $0.names.contains(token) }
    }

    public func option(named token: String) -> OptionSpec? {
        options.first { $0.names.contains(token) }
    }
}

/// A flag or option, for example `-r` / `--recursive`.
public struct OptionSpec: Codable, Equatable {
    public var names: [String]
    public var description: String?
    /// The value this option takes, if any (for `-o value` or `--flag=value`).
    public var argument: ArgSpec?
    public var isRepeatable: Bool

    public init(names: [String], description: String? = nil, argument: ArgSpec? = nil, isRepeatable: Bool = false) {
        self.names = names
        self.description = description
        self.argument = argument
        self.isRepeatable = isRepeatable
    }

    enum CodingKeys: String, CodingKey {
        case names, description, argument, isRepeatable
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        names = try c.decode([String].self, forKey: .names)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        argument = try c.decodeIfPresent(ArgSpec.self, forKey: .argument)
        isRepeatable = try c.decodeIfPresent(Bool.self, forKey: .isRepeatable) ?? false
    }
}

/// A positional argument.
public struct ArgSpec: Codable, Equatable {
    public var name: String?
    public var description: String?
    public var isOptional: Bool
    /// A filesystem template that triggers native path completion.
    public var template: ArgTemplate?
    /// Static suggestions for this argument (for example git remotes are not
    /// static, but log format names are).
    public var suggestions: [Suggestion]
    public var isVariadic: Bool

    public init(
        name: String? = nil,
        description: String? = nil,
        isOptional: Bool = false,
        template: ArgTemplate? = nil,
        suggestions: [Suggestion] = [],
        isVariadic: Bool = false
    ) {
        self.name = name
        self.description = description
        self.isOptional = isOptional
        self.template = template
        self.suggestions = suggestions
        self.isVariadic = isVariadic
    }

    enum CodingKeys: String, CodingKey {
        case name, description, isOptional, template, suggestions, isVariadic
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        isOptional = try c.decodeIfPresent(Bool.self, forKey: .isOptional) ?? false
        template = try c.decodeIfPresent(ArgTemplate.self, forKey: .template)
        suggestions = try c.decodeIfPresent([Suggestion].self, forKey: .suggestions) ?? []
        isVariadic = try c.decodeIfPresent(Bool.self, forKey: .isVariadic) ?? false
    }
}

public enum ArgTemplate: String, Codable, Equatable {
    case filepaths
    case folders
}

public struct Suggestion: Codable, Equatable {
    public var name: String
    public var description: String?

    public init(name: String, description: String? = nil) {
        self.name = name
        self.description = description
    }
}
