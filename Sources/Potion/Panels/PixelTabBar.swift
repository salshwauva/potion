import SwiftUI

/// The companion panel's section switcher, styled as pixel chrome. The labels
/// name the real sections in plain words; only their typeface is themed.
struct PixelTabBar: View {
    @Binding var selection: CompanionPanel.Section
    @EnvironmentObject private var theme: ThemeManager

    private let tabs: [(CompanionPanel.Section, String)] = [
        (.history, "HISTORY"),
        (.docs, "DOCS"),
        (.errors, "ERRORS"),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.0) { section, label in
                Button {
                    selection = section
                } label: {
                    Text(label)
                        .font(theme.chromeFont(size: 8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(selection == section ? theme.palette.textPrimary : theme.palette.textTertiary)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(selection == section ? theme.palette.cardBackground : .clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(selection == section ? theme.palette.rim.opacity(0.35) : .clear, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
