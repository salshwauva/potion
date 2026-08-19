import SwiftUI

/// The companion panel's surfaces.
///
/// The panel is a stack of rungs from the skin's own ladder rather than a flat
/// field with borders drawn on it: the canvas sits low, the header shelf sits
/// above it, cards sit above that, and the tab track is cut back below the
/// canvas. Each surface is a shallow gradient across its own rung, lit from the
/// top, which is what gives an edge somewhere to catch light without any of it
/// reading as a line.
enum PanelDepth {
    static let cardRadius: CGFloat = 9
    static let shelfShadow: CGFloat = 10
}

/// A card in the companion panel: the card rung, graded top to bottom, with a
/// lit upper edge and a dark lower one. No drop shadow. Elevation is carried by
/// the grade and the edge, which is the same way the surface ladder carries it
/// everywhere else in the app.
struct PanelCard: ViewModifier {
    var radius: CGFloat = PanelDepth.cardRadius
    var raised = false

    @EnvironmentObject private var theme: ThemeManager

    func body(content: Content) -> some View {
        let base = raised ? theme.palette.cardBackgroundRaised : theme.palette.cardBackground
        let top = base.mixed(with: theme.palette.cardBackgroundRaised, amount: raised ? 0.35 : 0.5)
        let bottom = base.mixed(with: theme.palette.panelBackground, amount: 0.28)

        return content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LinearGradient(colors: [top, base, bottom], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [theme.palette.rim.opacity(0.22), theme.palette.rim.opacity(0.04), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
}

/// A recessed track, cut back below the surface it sits on. Controls that live
/// in one read as pressed into the panel rather than floating on it.
struct PanelTrack: ViewModifier {
    var radius: CGFloat = 9

    @EnvironmentObject private var theme: ThemeManager

    /// A rung below the panel in either mode. Reaching for `terminalBackground`
    /// is wrong here: the ladder inverts under the light skins, where the well is
    /// the lightest surface in the app and a recess drawn from it comes out
    /// brighter than the panel it is cut into.
    private var sunk: Color {
        theme.mode == .dark
            ? theme.palette.terminalBackground
            : theme.palette.panelBackground.mixed(with: theme.palette.textPrimary, amount: 0.09)
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [sunk, sunk.mixed(with: theme.palette.panelBackground, amount: 0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.black.opacity(0.28), .clear, theme.palette.rim.opacity(0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func panelCard(radius: CGFloat = PanelDepth.cardRadius, raised: Bool = false) -> some View {
        modifier(PanelCard(radius: radius, raised: raised))
    }

    func panelTrack(radius: CGFloat = 9) -> some View {
        modifier(PanelTrack(radius: radius))
    }
}
