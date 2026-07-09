import Foundation

/// A single translated fragment of a command line, aligned to the source token
/// it came from.
public struct SubtitlePhrase: Equatable {
    public enum Confidence: Equatable {
        /// The meaning is known from a spec or the syntax table.
        case known
        /// The token was not recognized; the phrase says so honestly.
        case unknown
    }

    public var text: String
    public var confidence: Confidence
    public var sourceStart: Int?
    public var sourceEnd: Int?

    public init(text: String, confidence: Confidence = .known, sourceStart: Int? = nil, sourceEnd: Int? = nil) {
        self.text = text
        self.confidence = confidence
        self.sourceStart = sourceStart
        self.sourceEnd = sourceEnd
    }
}

public struct Subtitle: Equatable {
    public var phrases: [SubtitlePhrase]

    public init(phrases: [SubtitlePhrase]) {
        self.phrases = phrases
    }

    public var isEmpty: Bool { phrases.isEmpty }

    /// The phrases joined for display or for golden-file comparison.
    public var plainText: String {
        phrases.map(\.text).joined(separator: " · ")
    }
}

/// Translates a command line into plain English. It reuses the same tokenizer
/// and spec data as autocomplete: command, subcommand, option, and argument
/// descriptions come from the ``SpecEngine``; operators, redirects, and special
/// tokens come from the ``SyntaxTable``. Unknown tokens are labeled honestly and
/// never guessed.
public final class SubtitleRenderer {
    private let engine: SpecEngine
    private let syntax: SyntaxTable

    public init(engine: SpecEngine, syntax: SyntaxTable = .builtin) {
        self.engine = engine
        self.syntax = syntax
    }

    public func render(_ line: String) -> Subtitle {
        let tokens = Tokenizer.tokenize(line)
        guard !tokens.isEmpty else { return Subtitle(phrases: []) }

        var phrases: [SubtitlePhrase] = []
        for segment in Tokenizer.segments(tokens) {
            phrases += renderSegment(segment.tokens)
            if let terminator = segment.terminator {
                phrases.append(operatorPhrase(terminator))
            }
        }
        return Subtitle(phrases: phrases)
    }

    // MARK: Segment

    private func renderSegment(_ tokens: [Token]) -> [SubtitlePhrase] {
        guard let commandIndex = tokens.firstIndex(where: { $0.kind == .word }) else { return [] }

        // sudo is a prefix: describe it, then translate the rest as its own command.
        if tokens[commandIndex].value == "sudo" {
            let sudoPhrase = SubtitlePhrase(
                text: syntax.special("sudo", fallback: "as an administrator (be careful)"),
                sourceStart: tokens[commandIndex].start,
                sourceEnd: tokens[commandIndex].end
            )
            let rest = Array(tokens[(commandIndex + 1)...])
            return [sudoPhrase] + renderSegment(rest)
        }

        var phrases: [SubtitlePhrase] = []
        let commandToken = tokens[commandIndex]
        var context: CommandSpec? = engine.spec(for: commandToken.value)
        var index = commandIndex + 1

        if let spec = context {
            var deepest: CommandSpec?
            while index < tokens.count {
                let token = tokens[index]
                guard token.kind == .word, !token.value.hasPrefix("-") else { break }
                guard let sub = context?.subcommand(named: token.value) else { break }
                context = sub
                deepest = sub
                index += 1
            }
            let describing = deepest ?? spec
            phrases.append(SubtitlePhrase(
                text: lowerFirst(describing.description ?? describing.name),
                sourceStart: commandToken.start,
                sourceEnd: commandToken.end
            ))
        } else {
            let text = syntax.special("run_program", fallback: "run the program {name}")
                .replacingOccurrences(of: "{name}", with: commandToken.value)
            phrases.append(SubtitlePhrase(text: text, sourceStart: commandToken.start, sourceEnd: commandToken.end))
        }

        phrases += renderArgumentsAndFlags(tokens, from: index, context: context)
        return phrases
    }

    private func renderArgumentsAndFlags(_ tokens: [Token], from start: Int, context: CommandSpec?) -> [SubtitlePhrase] {
        var phrases: [SubtitlePhrase] = []
        var consumedArgs = 0
        var i = start

        while i < tokens.count {
            let token = tokens[i]

            if token.kind == .op {
                if let template = syntax.redirects[token.value] {
                    let file = (i + 1 < tokens.count && tokens[i + 1].kind == .word) ? tokens[i + 1] : nil
                    let fileText = file?.raw ?? "a file"
                    phrases.append(SubtitlePhrase(
                        text: template.replacingOccurrences(of: "{file}", with: fileText),
                        sourceStart: token.start,
                        sourceEnd: file?.end ?? token.end
                    ))
                    i += (file != nil ? 2 : 1)
                    continue
                }
                i += 1
                continue
            }

            let value = token.value

            if !token.wasQuoted, value == "~" {
                phrases.append(special("home", fallback: "your home folder", token))
                i += 1
                continue
            }

            if !token.wasQuoted, value.hasPrefix("$") {
                let name = variableName(value)
                let text = syntax.special("variable", fallback: "the value of {name}")
                    .replacingOccurrences(of: "{name}", with: name)
                phrases.append(SubtitlePhrase(text: text, sourceStart: token.start, sourceEnd: token.end))
                i += 1
                continue
            }

            // Long option with an attached value: --flag=value.
            if value.hasPrefix("--"), let equals = value.firstIndex(of: "=") {
                let name = String(value[..<equals])
                let attached = String(value[value.index(after: equals)...])
                phrases.append(optionPhrase(name: name, value: attached, context: context, token: token))
                i += 1
                continue
            }

            // Combined short flags: -rf expands to -r and -f.
            if value.hasPrefix("-"), !value.hasPrefix("--"), value.count > 2 {
                for character in value.dropFirst() {
                    phrases.append(optionPhrase(name: "-\(character)", value: nil, context: context, token: token))
                }
                i += 1
                continue
            }

            // A single option, possibly taking the next token as its value.
            if value.hasPrefix("-"), value != "-" {
                if let option = context?.option(named: value), option.argument != nil {
                    let valueToken = (i + 1 < tokens.count && tokens[i + 1].kind == .word) ? tokens[i + 1] : nil
                    phrases.append(optionPhrase(option: option, value: valueToken?.raw, token: token))
                    i += (valueToken != nil ? 2 : 1)
                } else {
                    phrases.append(optionPhrase(name: value, value: nil, context: context, token: token))
                    i += 1
                }
                continue
            }

            // A positional argument.
            phrases.append(argumentPhrase(context: context, consumed: consumedArgs, token: token))
            consumedArgs += 1
            i += 1
        }

        return phrases
    }

    // MARK: Phrase builders

    private func operatorPhrase(_ token: Token) -> SubtitlePhrase {
        if let text = syntax.operators[token.value] {
            return SubtitlePhrase(text: text, sourceStart: token.start, sourceEnd: token.end)
        }
        return SubtitlePhrase(text: token.value, confidence: .unknown, sourceStart: token.start, sourceEnd: token.end)
    }

    private func optionPhrase(name: String, value: String?, context: CommandSpec?, token: Token) -> SubtitlePhrase {
        if let option = context?.option(named: name) {
            return optionPhrase(option: option, value: value, token: token)
        }
        let honest = syntax.special("unknown_flag", fallback: "not sure what this flag does")
        return SubtitlePhrase(text: "\(name): \(honest)", confidence: .unknown, sourceStart: token.start, sourceEnd: token.end)
    }

    private func optionPhrase(option: OptionSpec, value: String?, token: Token) -> SubtitlePhrase {
        var text = lowerFirst(option.description ?? option.names.first ?? "")
        if let value {
            text += ": \(value)"
        }
        return SubtitlePhrase(text: text, sourceStart: token.start, sourceEnd: token.end)
    }

    private func argumentPhrase(context: CommandSpec?, consumed: Int, token: Token) -> SubtitlePhrase {
        let arg = context.flatMap { expectedArgument($0, consumed: consumed) }
        var base: String
        if let arg {
            if let description = arg.description {
                base = "\(lowerFirst(description)): \(token.raw)"
            } else if arg.template == .filepaths {
                base = "the path \(token.value)"
            } else if arg.template == .folders {
                base = "the folder \(token.value)"
            } else {
                base = "the value \(token.raw)"
            }
        } else {
            base = "the value \(token.raw)"
        }
        if containsGlob(token) {
            base += " (\(syntax.special("glob", fallback: "a pattern that matches files")))"
        }
        return SubtitlePhrase(text: base, sourceStart: token.start, sourceEnd: token.end)
    }

    private func special(_ key: String, fallback: String, _ token: Token) -> SubtitlePhrase {
        SubtitlePhrase(text: syntax.special(key, fallback: fallback), sourceStart: token.start, sourceEnd: token.end)
    }

    // MARK: Helpers

    private func expectedArgument(_ context: CommandSpec, consumed: Int) -> ArgSpec? {
        if consumed < context.args.count {
            return context.args[consumed]
        }
        if let last = context.args.last, last.isVariadic {
            return last
        }
        return nil
    }

    private func variableName(_ token: String) -> String {
        var name = String(token.dropFirst()) // drop $
        if name.hasPrefix("{") && name.hasSuffix("}") {
            name = String(name.dropFirst().dropLast())
        }
        return name
    }

    private func containsGlob(_ token: Token) -> Bool {
        guard !token.wasQuoted else { return false }
        return token.value.contains("*") || token.value.contains("?")
    }

    private func lowerFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.lowercased() + text.dropFirst()
    }
}
