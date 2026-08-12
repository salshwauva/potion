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
        CommandHighlighter.highlight(command, palette: theme.palette, cwd: cwd)
    }
}
