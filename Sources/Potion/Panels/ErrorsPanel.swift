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
        VStack {
            Spacer()
            Text("When a command fails, a plain-English explanation appears here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ErrorCardView: View {
    let item: IdentifiedErrorCard
    let onInsert: (ErrorFix) -> Void
    let subtitle: (String) -> Subtitle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(item.card.title)
                    .font(.headline)
            }
            Text(item.command)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Text(item.card.explanation)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            if !item.card.fixes.isEmpty {
                Divider()
                Text(item.card.fixes.count == 1 ? "Try this" : "Try one of these")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(Array(item.card.fixes.enumerated()), id: \.offset) { _, fix in
                    fixView(fix)
                }
            }
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.orange.opacity(0.25)))
    }

    private func fixView(_ fix: ErrorFix) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fix.description)
                .font(.callout)
            HStack(alignment: .top, spacing: 8) {
                Text(fix.command)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                Button("Insert") { onInsert(fix) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            let phrases = subtitle(fix.command)
            if !phrases.isEmpty {
                SubtitleText(subtitle: phrases, font: .caption)
            }
        }
    }
}
