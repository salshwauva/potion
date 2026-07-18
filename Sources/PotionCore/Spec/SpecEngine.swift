import Foundation

public struct Completion: Equatable {
    public enum Kind: Equatable {
        case command
        case subcommand
        case option
        case argument
        case path
    }

    /// The token text to place into the line.
    public var insertion: String
    /// The label shown in the popup.
    public var display: String
    public var description: String?
    public var kind: Kind

    public init(insertion: String, display: String, description: String? = nil, kind: Kind) {
        self.insertion = insertion
        self.display = display
        self.description = description
        self.kind = kind
    }
}

public struct CompletionResult: Equatable {
    /// Character index where the replacement begins.
    public var replaceStart: Int
    /// Character index where the replacement ends.
    public var replaceEnd: Int
    public var completions: [Completion]

    public init(replaceStart: Int, replaceEnd: Int, completions: [Completion]) {
        self.replaceStart = replaceStart
        self.replaceEnd = replaceEnd
        self.completions = completions
    }

    public static let empty = CompletionResult(replaceStart: 0, replaceEnd: 0, completions: [])
}

/// The single parser and spec-tree walker. It tokenizes a command line once and
/// serves two consumers: autocomplete (``complete``) and, in a later phase, the
/// subtitle renderer, which reuses ``describe`` over the same tokens.
///
/// Dynamic generators (live git branches and similar) are intentionally not
/// executed. The `argumentGenerator` seam is where they would attach later.
public final class SpecEngine {
    private let specsByName: [String: CommandSpec]
    private let commandNames: [String]

    /// Every known command, one entry per command (not per alias), sorted by
    /// name. Used to offer a browsable list of common commands.
    public let allSpecs: [CommandSpec]

    public init(specs: [CommandSpec]) {
        var map: [String: CommandSpec] = [:]
        for spec in specs {
            for name in spec.names {
                map[name] = spec
            }
        }
        self.specsByName = map
        self.commandNames = specs.flatMap(\.names).sorted()
        self.allSpecs = specs.sorted { $0.name < $1.name }
    }

    public func spec(for command: String) -> CommandSpec? {
        specsByName[command]
    }

    // MARK: Autocomplete

    public func complete(line: String, cursor: Int, cwd: String, files: FileLister) -> CompletionResult {
        let tokens = Tokenizer.tokenize(line)
        let clampedCursor = max(0, min(cursor, line.count))

        // Find the active token: the word token containing or ending at the cursor.
        let active = tokens.firstIndex { $0.kind == .word && $0.start < clampedCursor && clampedCursor <= $0.end }
        let activeToken = active.map { tokens[$0] }
        let prefix: String
        let replaceStart: Int
        let replaceEnd: Int
        if let token = activeToken {
            let prefixLength = clampedCursor - token.start
            prefix = String(Array(token.raw).prefix(prefixLength))
            replaceStart = token.start
            replaceEnd = token.end
        } else {
            prefix = ""
            replaceStart = clampedCursor
            replaceEnd = clampedCursor
        }

        let segmentWords = wordsInActiveSegment(tokens, cursor: replaceStart)

        let completions: [Completion]
        if segmentWords.isEmpty {
            completions = completeCommandName(prefix: prefix)
        } else {
            completions = completeWithinCommand(segmentWords: segmentWords, prefix: prefix, cwd: cwd, files: files)
        }

        return CompletionResult(replaceStart: replaceStart, replaceEnd: replaceEnd, completions: completions)
    }

    /// Word tokens of the command segment that contains the cursor, excluding the
    /// active token being completed.
    private func wordsInActiveSegment(_ tokens: [Token], cursor: Int) -> [Token] {
        var words: [Token] = []
        for token in tokens {
            if token.start >= cursor { break }
            if token.kind == .op && Tokenizer.controlOperators.contains(token.value) {
                words.removeAll()
            } else if token.kind == .word && token.end <= cursor {
                words.append(token)
            }
        }
        return words
    }

    private func completeCommandName(prefix: String) -> [Completion] {
        commandNames
            .filter { prefix.isEmpty || $0.hasPrefix(prefix) }
            .compactMap { name in
                guard let spec = specsByName[name] else { return nil }
                return Completion(insertion: name, display: name, description: spec.description, kind: .command)
            }
    }

    private func completeWithinCommand(segmentWords: [Token], prefix: String, cwd: String, files: FileLister) -> [Completion] {
        let commandToken = segmentWords[0].value
        guard var context = specsByName[commandToken] else {
            // Unknown command: still offer path completion for its arguments.
            return pathCompletions(prefix: prefix, cwd: cwd, files: files, foldersOnly: false)
        }

        // Descend through subcommands, counting consumed positional arguments.
        var consumedArgs = 0
        for token in segmentWords.dropFirst() {
            if token.value.hasPrefix("-") { continue }
            if let sub = context.subcommand(named: token.value) {
                context = sub
                consumedArgs = 0
            } else {
                consumedArgs += 1
            }
        }

        if prefix.hasPrefix("-") {
            return completeOptions(context: context, prefix: prefix)
        }

        var results: [Completion] = []

        results += context.subcommands
            .filter { spec in spec.names.contains { prefix.isEmpty || $0.hasPrefix(prefix) } }
            .map { spec in
                Completion(insertion: spec.name, display: spec.name, description: spec.description, kind: .subcommand)
            }

        if let arg = expectedArgument(context, consumed: consumedArgs) {
            results += arg.suggestions
                .filter { prefix.isEmpty || $0.name.hasPrefix(prefix) }
                .map { Completion(insertion: $0.name, display: $0.name, description: $0.description, kind: .argument) }

            if let template = arg.template {
                results += pathCompletions(prefix: prefix, cwd: cwd, files: files, foldersOnly: template == .folders)
            }
        }

        return results
    }

    private func expectedArgument(_ context: CommandSpec, consumed: Int) -> ArgSpec? {
        if consumed < context.args.count {
            return context.args[consumed]
        }
        if let last = context.args.last, last.isVariadic {
            return last
        }
        return nil
    }

    private func completeOptions(context: CommandSpec, prefix: String) -> [Completion] {
        context.options
            .flatMap { option -> [Completion] in
                option.names
                    .filter { prefix == "-" || $0.hasPrefix(prefix) }
                    .map { Completion(insertion: $0, display: $0, description: option.description, kind: .option) }
            }
    }

    // MARK: Path completion (native)

    private func pathCompletions(prefix: String, cwd: String, files: FileLister, foldersOnly: Bool) -> [Completion] {
        let (directoryPart, partial) = splitPath(prefix)
        let resolved = resolveDirectory(directoryPart, cwd: cwd)
        let entries = files.entries(inDirectory: resolved)

        return entries
            .filter { entry in
                let matchesPrefix: Bool
                if partial.isEmpty {
                    // Hide dotfiles unless the user has started typing a dot.
                    matchesPrefix = !entry.name.hasPrefix(".")
                } else {
                    // Case-insensitive, matching the default macOS filesystem.
                    matchesPrefix = entry.name.lowercased().hasPrefix(partial.lowercased())
                }
                guard matchesPrefix else { return false }
                return foldersOnly ? entry.isDirectory : true
            }
            .sorted { $0.name < $1.name }
            .map { entry in
                let insertion = directoryPart + entry.name + (entry.isDirectory ? "/" : "")
                let display = entry.name + (entry.isDirectory ? "/" : "")
                return Completion(insertion: insertion, display: display, description: nil, kind: .path)
            }
    }

    /// Splits a partial path into its directory portion (kept verbatim, including
    /// the trailing slash) and the final partial component.
    private func splitPath(_ path: String) -> (directory: String, partial: String) {
        guard let slash = path.lastIndex(of: "/") else {
            return ("", path)
        }
        let directory = String(path[...slash])
        let partial = String(path[path.index(after: slash)...])
        return (directory, partial)
    }

    private func resolveDirectory(_ directoryPart: String, cwd: String) -> String {
        if directoryPart.hasPrefix("/") {
            return NSString(string: directoryPart).standardizingPath
        }
        if directoryPart.hasPrefix("~") {
            return NSString(string: directoryPart).expandingTildeInPath
        }
        let base = directoryPart.isEmpty
            ? cwd
            : NSString(string: cwd).appendingPathComponent(directoryPart)
        return NSString(string: base).standardizingPath
    }
}
