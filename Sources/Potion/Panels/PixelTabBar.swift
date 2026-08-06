import SwiftUI

/// The companion panel's section switcher. The labels name the real sections in
/// plain words and are set in the UI face, not the pixel one: small caps in a
/// bitmap face lose their counters and run together. The pixel identity stays in
/// the wordmark and the section headings, where the size can carry it.
///
/// Selection reads twice, as a raised surface and as the active skin's mark, so
/// it survives both a squint and a colorblind viewer. Every mark is drawn inside
/// the tab's own bounds, so no skin can push the bar into the content below it.
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

    /// The fill and the skin's mark share a clip, so the mark tucks into the
    /// corners instead of running past them.
    private var background: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(fill)
            if isSelected { mark }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .animation(.easeOut(duration: 0.12), value: isHovering)
    }

    @ViewBuilder
    private var mark: some View {
        switch theme.skin.signature {
        case .rule:
            VStack {
                Spacer()
                Rectangle().fill(theme.palette.accent).frame(height: 2)
            }
        case .bracket:
            HStack {
                Rectangle().fill(theme.palette.accent).frame(width: 2)
                Spacer()
                Rectangle().fill(theme.palette.accent).frame(width: 2)
            }
            .padding(.vertical, 4)
        case .moonPhase:
            VStack {
                Spacer()
                crescent.padding(.bottom, 3)
            }
        case .star:
            VStack {
                HStack {
                    Spacer()
                    Text("✦")
                        .font(.system(size: 8))
                        .foregroundStyle(theme.palette.accent)
                }
                Spacer()
            }
            .padding(4)
        case .ribbon:
            VStack {
                Spacer()
                RibbonTail().fill(theme.palette.accent).frame(height: 5)
            }
        }
    }

    /// A filled dot with a bite taken out, clipped back to the dot.
    private var crescent: some View {
        Circle()
            .fill(theme.palette.accent)
            .frame(width: 7, height: 7)
            .overlay(
                Circle()
                    .fill(fill)
                    .frame(width: 6, height: 6)
                    .offset(x: 2.2)
            )
            .clipShape(Circle())
    }

    private var fill: Color {
        if isSelected { return theme.palette.cardBackground }
        return isHovering ? theme.palette.cardBackground.opacity(0.45) : .clear
    }
}

/// A bar notched into a V, so the selected tab reads as a ribbon bookmark.
private struct RibbonTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
