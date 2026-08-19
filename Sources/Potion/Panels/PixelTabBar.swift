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
        (.translator, "TRANSLATION"),
        (.suggestions, "SUGGEST"),
        (.help, "HELP")
    ]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(tabs, id: \.0) { section, label in
                TabButton(
                    label: label,
                    isSelected: selection == section,
                    action: { selection = section }
                )
            }
        }
        .padding(3)
        .panelTrack(radius: 10)
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
                .font(theme.labelFont(size: 12))
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
            if isSelected {
                RoundedRectangle(cornerRadius: 7, style: .continuous).fill(fillShape)
            } else {
                RoundedRectangle(cornerRadius: 7, style: .continuous).fill(fill)
            }

            // The selected tab is the only thing in the track that rises out of
            // it, so it takes the lit edge that goes with being raised.
            if isSelected {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [theme.palette.rim.opacity(0.30), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                mark
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
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
                        .font(theme.font(8))
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

    private var fillShape: LinearGradient {
        LinearGradient(
            colors: [
                theme.palette.cardBackground.mixed(with: theme.palette.cardBackgroundRaised, amount: 0.6),
                theme.palette.cardBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var fill: Color {
        if isSelected { return theme.palette.cardBackground }
        return isHovering ? theme.palette.cardBackground.opacity(0.4) : .clear
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
