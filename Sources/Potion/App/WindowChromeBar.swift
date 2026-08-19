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
        HStack(spacing: 12) {
            wordmark
            Spacer(minLength: 12)
            cwdLink
            Spacer(minLength: 12)
            quickActions
        }
        .padding(.leading, 78)
        .padding(.trailing, 14)
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    theme.palette.accent.opacity(0.32),
                    theme.palette.windowChrome
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.palette.accent.opacity(0.6)).frame(height: 1.5)
        }
    }

    private var wordmark: some View {
        (Text("POT")
            + Text("I").foregroundColor(theme.palette.accent)
            + Text("ON"))
            .font(theme.chromeFont(size: 13))
            .foregroundStyle(theme.palette.textPrimary)
            .kerning(1.2)
    }

    @ViewBuilder
    private var cwdLink: some View {
        if let cwd = controller.currentDirectory, FolderPath.isFolder(cwd) {
            Button {
                FolderPath.open(cwd)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.palette.accentSoft)
                    Text(FolderPath.display(from: cwd))
                        .font(theme.font(11, mono: true))
                        .foregroundStyle(theme.palette.accentSoft)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }
            .buttonStyle(.plain)
            .help("Open in Finder")
            .linkCursor()
        } else {
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.system(size: 10))
                    .foregroundStyle(theme.palette.textTertiary)
                Text(controller.currentDirectory.map(FolderPath.display) ?? "~")
                    .font(theme.font(11, mono: true))
                    .foregroundStyle(theme.palette.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            Button {
                theme.toggleMode()
            } label: {
                Image(systemName: theme.mode == .dark ? "sun.max.fill" : "moon.stars.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.palette.accentSoft)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 5).fill(theme.palette.cardBackground))
            }
            .buttonStyle(.plain)
            .help("Toggle Light / Dark Mode")

            Button {
                controller.toggleQuickHelp()
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "questionmark.circle")
                    Text("Help")
                }
                .font(theme.font(11, weight: .medium))
                .foregroundStyle(theme.palette.textPrimary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).fill(theme.palette.cardBackground))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("h", modifiers: [.command])
            .help("Quick Help & Cheatsheet (⌘H)")

            Button {
                controller.toggleSidebar()
            } label: {
                Image(systemName: controller.isSidebarVisible ? "sidebar.right" : "sidebar.right")
                    .font(.system(size: 12))
                    .foregroundStyle(controller.isSidebarVisible ? theme.palette.accent : theme.palette.textSecondary)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 5).fill(controller.isSidebarVisible ? theme.palette.cardBackgroundRaised : theme.palette.cardBackground))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("b", modifiers: [.command])
            .help("Toggle Sidebar (⌘B)")
        }
    }
}
