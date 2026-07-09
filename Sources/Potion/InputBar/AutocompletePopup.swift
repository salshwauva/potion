import PotionCore
import SwiftUI

/// The suggestion list shown above the input bar. Tab accepts the highlighted
/// row, the arrows move the highlight, Esc dismisses, and a click accepts
/// directly. Enter never touches this list: it always runs the typed line.
struct AutocompletePopup: View {
    @ObservedObject var controller: TerminalController

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
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: 460, alignment: .leading)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.12)))
            .shadow(radius: 12, y: 4)
        }
    }

    private func row(_ completion: Completion, selected: Bool) -> some View {
        HStack(spacing: 10) {
            Text(completion.display)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(selected ? Color.accentColor : .primary)
                .layoutPriority(1)
            if let description = completion.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(selected ? Color.accentColor.opacity(0.15) : Color.clear)
    }
}
