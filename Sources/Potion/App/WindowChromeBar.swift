import Foundation
import SwiftUI

/// The pixel wordmark strip along the top of the window. With the native title
/// bar hidden, this carries the Potion identity: the mark on the left (with room
/// for the traffic lights) and the working directory on the right. The name
/// lives here, in the chrome, never in the interface copy below it.
struct WindowChromeBar: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        HStack(spacing: 10) {
            wordmark
            Spacer(minLength: 12)
            Text(cwdText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(theme.palette.textTertiary)
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(.leading, 78)
        .padding(.trailing, 14)
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .background(theme.palette.windowChrome)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.palette.divider).frame(height: 1)
        }
    }

    private var wordmark: some View {
        (Text("POT")
            + Text("I").foregroundColor(theme.palette.accent)
            + Text("ON"))
            .font(theme.chromeFont(size: 12))
            .foregroundStyle(theme.palette.textPrimary)
            .kerning(1)
    }

    private var cwdText: String {
        guard let path = controller.currentDirectory else { return "" }
        let home = NSHomeDirectory()
        if path == home { return "~" }
        if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
        return path
    }
}
