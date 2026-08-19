import PotionCore
import SwiftUI

/// The Suggestions Panel: provides smart, context-aware command recommendations
/// and next-step learning suggestions based on current working directory and history.
struct SuggestionsPanel: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerView
                suggestionsList
                learningTipsSection
            }
            .padding(12)
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SMART SUGGESTIONS")
                .font(theme.labelFont(size: 10))
                .tracking(theme.labelTracking)
                .foregroundStyle(theme.palette.rim)
            Text("Recommended Actions")
                .font(theme.headingFont(size: 15))
                .foregroundStyle(theme.palette.textPrimary)
            if let cwd = controller.currentDirectory {
                Text(FolderPath.display(from: cwd))
                    .font(theme.font(11, mono: true))
                    .foregroundStyle(theme.palette.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            let suggestions = controller.contextualSuggestions()

            ForEach(suggestions) { item in
                suggestionCard(item)
            }
        }
    }

    private func suggestionCard(_ item: CommandSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let badge = item.badge {
                    Text(badge)
                        .font(theme.labelFont(size: 9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(theme.palette.accent.opacity(0.18)))
                        .foregroundStyle(theme.palette.accent)
                }

                Text(item.title)
                    .font(theme.font(13, weight: .semibold))
                    .foregroundStyle(theme.palette.textPrimary)

                Spacer()

                Button("Insert") {
                    controller.insertIntoInput(item.command)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text(item.description)
                .font(theme.font(12))
                .foregroundStyle(theme.palette.textSecondary)

            HStack(spacing: 6) {
                Text(item.command)
                    .font(theme.font(12, mono: true))
                    .foregroundStyle(theme.palette.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .panelCard(radius: 5, raised: true)
                
                Spacer()

                let sub = controller.subtitle(for: item.command)
                if !sub.isEmpty {
                    SubtitleText(subtitle: sub, size: 10)
                        .lineLimit(1)
                }
            }
        }
        .padding(11)
        .panelCard(radius: 8)
    }

    private var learningTipsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TERMINAL TIPS")
                .font(theme.labelFont(size: 10))
                .tracking(theme.labelTracking)
                .foregroundStyle(theme.palette.rim)

            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "star.fill", title: "Tab Autocomplete", desc: "Press Tab to instantly auto-complete paths, flags, and command names.")
                tipRow(icon: "arrow.up.and.down", title: "History Recall", desc: "Press Up/Down arrow keys in the input bar to cycle through previous commands.")
                tipRow(icon: "text.book.closed", title: "Live Translation", desc: "Watch the Subtitle bar as you type to see what your command will actually do.")
                tipRow(icon: "command", title: "Quick Shortcuts", desc: "Use ⌘H for Help Cheatsheet, ⌘B to toggle Sidebar, and ⌘K to clear terminal.")
            }
            .padding(11)
            .panelCard(radius: 8)
        }
    }

    private func tipRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(theme.palette.accentSoft)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.font(12, weight: .semibold))
                    .foregroundStyle(theme.palette.textPrimary)
                Text(desc)
                    .font(theme.font(11))
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
    }
}
