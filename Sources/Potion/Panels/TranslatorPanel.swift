import PotionCore
import SwiftUI

/// The Translator Panel: deconstructs the current command draft or last run command
/// into color-coded tokens, flags, arguments, and operators, with a plain-English translation.
struct TranslatorPanel: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    private var activeLine: String {
        if !controller.draft.isEmpty {
            return controller.draft
        }
        return controller.records.last?.command ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                headerView
                
                if activeLine.trimmingCharacters(in: .whitespaces).isEmpty {
                    emptyState
                } else {
                    heroTranslationCard
                    tokenBreakdownSection
                }
            }
            .padding(12)
        }
    }

    private var headerView: some View {
        HStack {
            Text("COMMAND TRANSLATOR")
                .font(theme.labelFont(size: 10))
                .tracking(theme.labelTracking)
                .foregroundStyle(theme.palette.rim)
            Spacer()
            if !controller.draft.isEmpty {
                Text("LIVE DRAFT")
                    .font(theme.labelFont(size: 9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(theme.palette.accent.opacity(0.2)))
                    .foregroundStyle(theme.palette.accent)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 40)
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(theme.palette.accentSoft)
            Text("Type a command to translate")
                .font(theme.font(14, weight: .semibold))
                .foregroundStyle(theme.palette.textPrimary)
            Text("As you type in the input bar, Potion breaks down each command verb, flag, argument, and pipe into plain English.")
                .font(theme.font(12))
                .foregroundStyle(theme.palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .panelCard(radius: 8)
    }

    private var heroTranslationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Meaning")
                    .font(theme.labelFont(size: 11))
                    .foregroundStyle(theme.palette.textTertiary)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(activeLine, forType: .string)
                } label: {
                    Label("Copy Command", systemImage: "doc.on.doc")
                        .font(theme.font(11))
                }
                .buttonStyle(.potionLink)
            }

            let sub = controller.subtitle(for: activeLine)
            if !sub.isEmpty {
                SubtitleText(subtitle: sub, size: 14)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .panelCard(radius: 6, raised: true)
            } else {
                Text(activeLine)
                    .font(theme.font(13, mono: true))
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
        .padding(12)
        .panelCard(radius: 8)
    }

    private var tokenBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SYNTAX ELEMENTS")
                .font(theme.labelFont(size: 10))
                .tracking(theme.labelTracking)
                .foregroundStyle(theme.palette.rim)

            let tokens = controller.tokenBreakdown(for: activeLine)
            ForEach(tokens) { item in
                tokenCard(item)
            }
        }
    }

    private func tokenCard(_ item: IdentifiedTokenBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            let color = CommandHighlighter.color(for: item.domain, palette: theme.palette)
            HStack(spacing: 8) {
                Text(item.token.raw)
                    .font(theme.font(13, weight: .semibold, mono: true))
                    .foregroundStyle(theme.palette.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.18)))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.4), lineWidth: 1))

                Spacer()

                Text(item.category.uppercased())
                    .font(theme.labelFont(size: 9))
                    .tracking(0.6)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(color.opacity(0.15)))
                    .foregroundStyle(color)
            }

            Text(item.explanation)
                .font(theme.font(12))
                .foregroundStyle(item.confidence == .known ? theme.palette.textSecondary : theme.palette.textTertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .panelCard(radius: 7)
    }

    private func tokenColor(for category: String) -> Color {
        switch category {
        case "Command": return theme.palette.accent
        case "Subcommand": return theme.palette.accentSoft
        case "Option Flag": return theme.palette.running
        case "Operator": return theme.palette.sparkle
        case "Variable": return theme.palette.success
        default: return theme.palette.textSecondary
        }
    }
}
