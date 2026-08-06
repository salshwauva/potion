import PotionCore
import SwiftUI

/// The suggestion list shown above the input bar. Tab accepts the highlighted
/// row, the arrows move the highlight, Esc dismisses, and a click accepts
/// directly. Enter never touches this list: it always runs the typed line.
struct AutocompletePopup: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    private let maxRows = 8

    var body: some View {
        if controller.isCompletionVisible {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(controller.completions.prefix(maxRows).enumerated()), id: \.offset) { index, completion in
                    row(completion, selected: index == controller.selectedCompletion)
                        .contentShape(Rectangle())
                        .onTapGesture { controller.chooseCompletion(at: index) }
                    if index < min(controller.completions.count, maxRows) - 1 {
                        Divider().opacity(0.4)
                    }
                }
                if controller.completions.count > maxRows {
                    Text("and \(controller.completions.count - maxRows) more")
                        .font(theme.font(10))
                        .foregroundStyle(theme.palette.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: 460, alignment: .leading)
            .background(theme.palette.cardBackgroundRaised)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(theme.palette.rim.opacity(0.35)))
            .shadow(radius: 12, y: 4)
        }
    }

    private func row(_ completion: Completion, selected: Bool) -> some View {
        HStack(spacing: 10) {
            Text(completion.display)
                .font(theme.font(13, mono: true))
                .foregroundStyle(theme.palette.textPrimary)
                .layoutPriority(1)
            if let description = completion.description {
                Text(description)
                    .font(theme.font(11))
                    .foregroundStyle(theme.palette.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(alignment: .leading) {
            // Selection is a tint plus a rule, never a text-color change: accent
            // pink on the raised card only reaches 3.8:1, short of AA for body.
            ZStack(alignment: .leading) {
                theme.palette.accent.opacity(selected ? 0.18 : 0)
                theme.palette.accent
                    .frame(width: 2)
                    .opacity(selected ? 1 : 0)
            }
        }
    }
}
