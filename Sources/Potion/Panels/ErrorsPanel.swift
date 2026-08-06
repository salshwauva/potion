import PotionCore
import SwiftUI

/// An error card tied to the command that produced it.
struct IdentifiedErrorCard: Identifiable, Equatable {
    let id: UUID
    let command: String
    let card: ErrorCard
}

/// The companion panel's Error section. Each failed command gets a gentle,
/// literal explanation and concrete fixes shown as real commands. Fixes insert
/// into the input bar; they never run on their own. The raw output stays in the
/// terminal untouched.
struct ErrorsPanel: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Group {
            if controller.errorCards.isEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(controller.errorCards) { item in
                        ErrorCardView(item: item) { fix in
                            controller.insertIntoInput(fix.command)
                        } subtitle: { command in
                            controller.subtitle(for: command)
                        }
                        .id(item.id)
                    }
                }
                .padding(10)
            }
            .onChange(of: controller.focusedErrorId) { _, newValue in
                guard let newValue else { return }
                withAnimation { proxy.scrollTo(newValue, anchor: .top) }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            PixelGlyph(glyph: theme.skin.motif[1], cell: 3)
                .opacity(0.85)
            Text("When a command fails, a plain-English explanation appears here.")
                .font(theme.font(13))
                .foregroundStyle(theme.palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ErrorCardView: View {
    let item: IdentifiedErrorCard
    let onInsert: (ErrorFix) -> Void
    let subtitle: (String) -> Subtitle

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(theme.palette.running)
                Text(item.card.title)
                    .font(theme.font(14, weight: .semibold))
                    .foregroundStyle(theme.palette.textPrimary)
            }
            Text(item.command)
                .font(theme.font(11, mono: true))
                .foregroundStyle(theme.palette.textSecondary)
                .textSelection(.enabled)
            Text(item.card.explanation)
                .font(theme.font(13))
                .foregroundStyle(theme.palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !item.card.fixes.isEmpty {
                Divider()
                Text(item.card.fixes.count == 1 ? "Try this" : "Try one of these")
                    .font(theme.font(11, weight: .semibold))
                    .foregroundStyle(theme.palette.textSecondary)
                ForEach(Array(item.card.fixes.enumerated()), id: \.offset) { _, fix in
                    fixView(fix)
                }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.palette.failure.opacity(0.10)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(theme.palette.rim.opacity(0.4)))
    }

    private func fixView(_ fix: ErrorFix) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fix.description)
                .font(theme.font(13))
            HStack(alignment: .top, spacing: 8) {
                Text(fix.command)
                    .font(theme.font(13, mono: true))
                    .foregroundStyle(theme.palette.textPrimary)
                    .textSelection(.enabled)
                    .padding(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(theme.palette.cardBackground))
                Button("Insert") { onInsert(fix) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            let phrases = subtitle(fix.command)
            if !phrases.isEmpty {
                SubtitleText(subtitle: phrases, size: 11)
            }
        }
    }
}
