import AppKit
import PotionCore
import SwiftUI

/// Renders a command line verbatim, turning any argument that resolves to an
/// existing folder into a link that opens it in Finder. Paths are resolved
/// against the working directory the command ran in, so relative paths work.
struct CommandText: View {
    let command: String
    let cwd: String?
    var font: Font = .system(.body, design: .monospaced)

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Text(attributed)
            .font(font)
            .textSelection(.enabled)
            .environment(\.openURL, OpenURLAction { url in
                guard url.isFileURL else { return .systemAction }
                NSWorkspace.shared.open(url)
                return .handled
            })
    }

    private var attributed: AttributedString {
        let base = FolderPath.filesystemPath(from: cwd ?? FileManager.default.currentDirectoryPath)
        let characters = Array(command)
        var result = AttributedString()
        var cursor = 0

        for token in Tokenizer.tokenize(command) {
            if token.start > cursor {
                result.append(AttributedString(String(characters[cursor..<token.start])))
            }
            var run = AttributedString(token.raw)
            if token.kind == .word, let url = FolderPath.folderURL(token: token.value, base: base) {
                run.foregroundColor = theme.palette.accent
                run.underlineStyle = .single
                run.link = url
            } else {
                run.foregroundColor = theme.palette.textPrimary
            }
            result.append(run)
            cursor = token.end
        }
        if cursor < characters.count {
            result.append(AttributedString(String(characters[cursor...])))
        }
        return result
    }
}
