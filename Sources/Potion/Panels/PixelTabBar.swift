import SwiftUI

/// The companion panel's section switcher. The labels name the real sections in
/// plain words and are set in the UI face, not the pixel one: small caps in a
/// bitmap face lose their counters and run together. The pixel identity stays in
/// the wordmark and the section headings, where the size can carry it.
///
/// Selection reads twice, as a raised surface and an accent rule beneath it, so
/// it survives both a squint and a colorblind viewer.
struct PixelTabBar: View {
    @Binding var selection: CompanionPanel.Section
    @EnvironmentObject private var theme: ThemeManager

    private let tabs: [(CompanionPanel.Section, String)] = [
        (.history, "HISTORY"),
        (.docs, "DOCS"),
        (.errors, "ERRORS"),
    ]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(tabs, id: \.0) { section, label in
                TabButton(
                    label: label,
                    isSelected: selection == section,
                    action: { selection = section }
                )
            }
        }
    }
}

private struct TabButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject private var theme: ThemeManager
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(theme.labelFont(size: 11))
                .tracking(theme.labelTracking)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .foregroundStyle(isSelected ? theme.palette.textPrimary : theme.palette.textSecondary)
                .background(background)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// The fill and the accent rule share a clip, so the rule tucks into the
    /// corners instead of running past them.
    private var background: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 6).fill(fill)
            Rectangle()
                .fill(theme.palette.accent)
                .frame(height: 2)
                .opacity(isSelected ? 1 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }

    private var fill: Color {
        if isSelected { return theme.palette.cardBackground }
        return isHovering ? theme.palette.cardBackground.opacity(0.45) : .clear
    }
}
