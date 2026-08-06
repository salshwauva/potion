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
            cwdLink
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

    @ViewBuilder
    private var cwdLink: some View {
        if let cwd = controller.currentDirectory, FolderPath.isFolder(cwd) {
            Button {
                FolderPath.open(cwd)
            } label: {
                Text(FolderPath.display(from: cwd))
                    .font(theme.font(12, mono: true))
                    .foregroundStyle(theme.palette.accentSoft)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            .buttonStyle(.plain)
            .help("Open in Finder")
            .linkCursor()
        } else {
            Text(controller.currentDirectory.map(FolderPath.display) ?? "")
                .font(theme.font(12, mono: true))
                .foregroundStyle(theme.palette.textTertiary)
                .lineLimit(1)
                .truncationMode(.head)
        }
    }
}
