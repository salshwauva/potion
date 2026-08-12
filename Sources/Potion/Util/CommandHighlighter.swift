import AppKit
import PotionCore
import SwiftUI

/// Defines domain categories for CLI tools, providing domain-specific syntax colors
/// for macOS, Xcode/Swift, Node/NPM, Git, Homebrew, and Search commands.
enum CommandDomain: String, CaseIterable {
    case macosSystem
    case xcodeSwift
    case nodeWeb
    case gitVCS
    case packageManager
    case searchUtil
    case optionFlag
    case operatorControl
    case generic

    var displayName: String {
        switch self {
        case .macosSystem: return "macOS System"
        case .xcodeSwift: return "Xcode & Swift"
        case .nodeWeb: return "Node & Web"
        case .gitVCS: return "Git & VCS"
        case .packageManager: return "Package Manager"
        case .searchUtil: return "Search & Utilities"
        case .optionFlag: return "Option Flag"
        case .operatorControl: return "Shell Operator"
        case .generic: return "Command"
        }
    }

    static func classify(token: Token, positionInSegment: Int) -> CommandDomain {
        if token.kind == .op {
            return .operatorControl
        }
        
        let value = token.value
        if value.hasPrefix("-") {
            return .optionFlag
        }

        guard positionInSegment == 0 else {
            return .generic
        }

        switch value {
        case "ls", "cd", "pwd", "cp", "mv", "rm", "mkdir", "rmdir", "chmod", "chown",
             "open", "pbcopy", "pbpaste", "defaults", "sw_vers", "system_profiler",
             "lsof", "kill", "ps", "top", "df", "du", "whoami", "sudo", "launchctl":
            return .macosSystem

        case "xcodebuild", "xcodegen", "swift", "swiftc", "xcode-select", "simctl",
             "lldb", "instruments", "agvtool", "xctest":
            return .xcodeSwift

        case "npm", "npx", "node", "yarn", "pnpm", "bun", "deno", "tsc", "vite", "next":
            return .nodeWeb

        case "git", "gh":
            return .gitVCS

        case "brew", "pip", "pip3", "python", "python3", "ruby", "gem", "cargo",
             "rustc", "docker", "kubectl":
            return .packageManager

        case "grep", "find", "cat", "less", "head", "tail", "wc", "sed", "awk",
             "curl", "wget", "ping", "ssh":
            return .searchUtil

        default:
            return .generic
        }
    }
}

/// Utility for producing syntax-highlighted AttributedString instances.
enum CommandHighlighter {

    static func color(for domain: CommandDomain, palette: PotionPalette) -> Color {
        switch domain {
        case .macosSystem: return Color(red: 0.35, green: 0.90, blue: 0.95) // Cyan
        case .xcodeSwift: return Color(red: 1.00, green: 0.60, blue: 0.25)  // Orange / Flame
        case .nodeWeb: return Color(red: 0.35, green: 0.92, blue: 0.55)     // Emerald Green
        case .gitVCS: return Color(red: 0.85, green: 0.55, blue: 1.00)      // Amethyst Purple
        case .packageManager: return Color(red: 1.00, green: 0.84, blue: 0.35) // Gold / Brass
        case .searchUtil: return Color(red: 0.45, green: 0.75, blue: 1.00)   // Sky Blue
        case .optionFlag: return Color(red: 1.00, green: 0.48, blue: 0.65)   // Rose / Crimson
        case .operatorControl: return palette.sparkle
        case .generic: return palette.textPrimary
        }
    }

    static func nsColor(for domain: CommandDomain, palette: PotionPalette) -> NSColor {
        NSColor(color(for: domain, palette: palette))
    }

    static func highlight(_ command: String, palette: PotionPalette, cwd: String? = nil) -> AttributedString {
        let tokens = Tokenizer.tokenize(command)
        let characters = Array(command)
        var result = AttributedString()
        var cursor = 0
        let base = FolderPath.filesystemPath(from: cwd ?? FileManager.default.currentDirectoryPath)

        let segments = Tokenizer.segments(tokens)
        var tokenDomainMap: [Int: CommandDomain] = [:]

        for segment in segments {
            for (pos, token) in segment.tokens.enumerated() {
                if let idx = tokens.firstIndex(where: { $0.start == token.start && $0.raw == token.raw }) {
                    tokenDomainMap[idx] = CommandDomain.classify(token: token, positionInSegment: pos)
                }
            }
        }

        for (index, token) in tokens.enumerated() {
            if token.start > cursor {
                result.append(AttributedString(String(characters[cursor..<token.start])))
            }
            var run = AttributedString(token.raw)
            let domain = tokenDomainMap[index] ?? .generic

            if token.kind == .word, let url = FolderPath.folderURL(token: token.value, base: base) {
                run.foregroundColor = palette.accent
                run.underlineStyle = .single
                run.link = url
            } else {
                run.foregroundColor = color(for: domain, palette: palette)
            }

            result.append(run)
            cursor = token.end
        }

        if cursor < characters.count {
            result.append(AttributedString(String(characters[cursor...])))
        }

        return result
    }

    static func highlightNS(_ command: String, palette: PotionPalette) -> NSAttributedString {
        let tokens = Tokenizer.tokenize(command)
        let result = NSMutableAttributedString(string: command, attributes: [
            .foregroundColor: NSColor(palette.textPrimary)
        ])

        let segments = Tokenizer.segments(tokens)
        for segment in segments {
            for (pos, token) in segment.tokens.enumerated() {
                let domain = CommandDomain.classify(token: token, positionInSegment: pos)
                let range = NSRange(location: token.start, length: token.end - token.start)
                if NSMaxRange(range) <= command.utf16.count {
                    result.addAttribute(.foregroundColor, value: nsColor(for: domain, palette: palette), range: range)
                }
            }
        }

        return result
    }
}
