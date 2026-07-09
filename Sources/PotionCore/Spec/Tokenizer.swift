import Foundation

/// A single lexical token of a command line, retaining enough position and
/// quoting information to drive both autocomplete (cursor mapping) and subtitle
/// rendering (token-to-phrase alignment).
public struct Token: Equatable {
    public enum Kind: Equatable {
        case word
        /// A control or redirection operator such as `|`, `&&`, `>`, `2>`.
        case op
    }

    /// The decoded value with quotes and escapes removed.
    public var value: String
    /// The exact substring as typed.
    public var raw: String
    /// Character index of the first character in the source line.
    public var start: Int
    /// Character index just past the last character.
    public var end: Int
    public var kind: Kind
    public var wasQuoted: Bool

    public init(value: String, raw: String, start: Int, end: Int, kind: Kind, wasQuoted: Bool = false) {
        self.value = value
        self.raw = raw
        self.start = start
        self.end = end
        self.kind = kind
        self.wasQuoted = wasQuoted
    }
}

/// Splits a command line into tokens, aware of single and double quotes,
/// backslash escapes, and the common shell operators.
public enum Tokenizer {
    /// Control operators that separate one command from the next.
    public static let controlOperators: Set<String> = ["|", "||", "&&", ";", "&", "|&"]

    public static func tokenize(_ line: String) -> [Token] {
        let chars = Array(line)
        var tokens: [Token] = []
        var i = 0
        let n = chars.count

        while i < n {
            let c = chars[i]

            if c == " " || c == "\t" {
                i += 1
                continue
            }

            if let (op, length) = matchOperator(chars, at: i) {
                tokens.append(Token(
                    value: op,
                    raw: op,
                    start: i,
                    end: i + length,
                    kind: .op
                ))
                i += length
                continue
            }

            // A word, possibly quoted or escaped.
            let start = i
            var value = ""
            var wasQuoted = false
            while i < n {
                let ch = chars[i]
                if ch == " " || ch == "\t" { break }
                if isOperatorStart(chars, at: i) { break }
                if ch == "'" {
                    wasQuoted = true
                    i += 1
                    while i < n && chars[i] != "'" {
                        value.append(chars[i])
                        i += 1
                    }
                    if i < n { i += 1 } // closing quote
                } else if ch == "\"" {
                    wasQuoted = true
                    i += 1
                    while i < n && chars[i] != "\"" {
                        if chars[i] == "\\" && i + 1 < n {
                            i += 1
                            value.append(chars[i])
                        } else {
                            value.append(chars[i])
                        }
                        i += 1
                    }
                    if i < n { i += 1 }
                } else if ch == "\\" && i + 1 < n {
                    i += 1
                    value.append(chars[i])
                    i += 1
                } else {
                    value.append(ch)
                    i += 1
                }
            }
            let raw = String(chars[start..<i])
            tokens.append(Token(value: value, raw: raw, start: start, end: i, kind: .word, wasQuoted: wasQuoted))
        }

        return tokens
    }

    /// Groups tokens into command segments, splitting on control operators. The
    /// operator that ended each segment is returned alongside its tokens.
    public static func segments(_ tokens: [Token]) -> [(tokens: [Token], terminator: Token?)] {
        var result: [(tokens: [Token], terminator: Token?)] = []
        var current: [Token] = []
        for token in tokens {
            if token.kind == .op && controlOperators.contains(token.value) {
                result.append((current, token))
                current = []
            } else {
                current.append(token)
            }
        }
        if !current.isEmpty || result.isEmpty {
            result.append((current, nil))
        }
        return result
    }

    // MARK: Operators

    private static func isOperatorStart(_ chars: [Character], at i: Int) -> Bool {
        matchOperator(chars, at: i) != nil
    }

    /// Matches the longest operator at `i`, returning its text and length.
    private static func matchOperator(_ chars: [Character], at i: Int) -> (String, Int)? {
        let n = chars.count
        func at(_ k: Int) -> Character? { k < n ? chars[k] : nil }

        // File-descriptor redirects like 2> and 2>>.
        if let d = at(i), d.isNumber, at(i + 1) == ">" {
            if at(i + 2) == ">" { return ("\(d)>>", 3) }
            return ("\(d)>", 2)
        }

        switch at(i) {
        case "|":
            if at(i + 1) == "|" { return ("||", 2) }
            if at(i + 1) == "&" { return ("|&", 2) }
            return ("|", 1)
        case "&":
            if at(i + 1) == "&" { return ("&&", 2) }
            return ("&", 1)
        case ">":
            if at(i + 1) == ">" { return (">>", 2) }
            return (">", 1)
        case "<":
            return ("<", 1)
        case ";":
            return (";", 1)
        default:
            return nil
        }
    }
}
