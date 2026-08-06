import AppKit
import CoreText
import SwiftUI

/// The Potion palette. Colors are tokens so nothing downstream hardcodes a value.
/// The witchy colors live in the chrome, panels, and accents. The terminal's own
/// text area uses a separate, conventional, high-legibility scheme because
/// readability there is load-bearing.
///
/// Surfaces are a five rung ladder on a single hue (268), varying lightness only.
/// The terminal is the darkest well and each layer of chrome steps up from it, so
/// depth comes from the ladder rather than from borders. Adjacent rungs sit 4 to 8
/// points of HSL lightness apart: enough to read as structure, quiet in isolation.
struct PotionPalette {
    // Surfaces, darkest first.
    let terminalBackground = Color(red: 0.073, green: 0.045, blue: 0.105)
    let panelBackground = Color(red: 0.112, green: 0.074, blue: 0.156)
    let windowChrome = Color(red: 0.151, green: 0.102, blue: 0.208)
    let cardBackground = Color(red: 0.230, green: 0.167, blue: 0.303)
    let cardBackgroundRaised = Color(red: 0.295, green: 0.219, blue: 0.381)

    // Accents (pink, magenta, lavender).
    let accent = Color(red: 1.00, green: 0.40, blue: 0.70)
    let accentSoft = Color(red: 0.82, green: 0.71, blue: 1.00)
    let rim = Color(red: 1.00, green: 0.55, blue: 0.78)

    // Text, four levels. Every level clears WCAG AA on the surfaces it is used
    // on; `textMuted` is for disabled controls only, which 1.4.3 exempts.
    let textPrimary = Color(red: 0.94, green: 0.92, blue: 0.99)
    let textSecondary = Color(red: 0.78, green: 0.72, blue: 0.89)
    let textTertiary = Color(red: 0.66, green: 0.60, blue: 0.78)
    let textMuted = Color(red: 0.50, green: 0.45, blue: 0.61)

    // Status.
    let success = Color(red: 0.44, green: 0.91, blue: 0.70)
    let running = Color(red: 1.00, green: 0.79, blue: 0.42)
    let failure = Color(red: 1.00, green: 0.50, blue: 0.61)

    let divider = Color.white.opacity(0.14)

    /// The terminal's own body text. Held a little under `textPrimary`: the well
    /// is the darkest surface in the app and pure white on it is tiring to read
    /// for as long as a terminal gets read.
    let terminalForeground = Color(red: 0.91, green: 0.88, blue: 0.96)

    // AppKit forms, for SwiftTerm's native color properties.
    var terminalBackgroundNS: NSColor { NSColor(terminalBackground) }
    var terminalForegroundNS: NSColor { NSColor(terminalForeground) }
    var caretNS: NSColor { NSColor(accent) }
    var selectionNS: NSColor { NSColor(rim).withAlphaComponent(0.35) }
}

/// A pairing of a display face for chrome and a readable face for body and
/// terminal text. The pixel faces are never used for the terminal body, for
/// subtitles, or for micro labels; legibility comes first in all three.
enum FontPairing: String, CaseIterable, Identifiable {
    case arcade
    case glow
    case clean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .arcade: return "Arcade"
        case .glow: return "Glow"
        case .clean: return "Clean"
        }
    }

    /// Family name for chrome, headings, and badges. Nil uses a system face.
    var chromeFontName: String? {
        switch self {
        case .arcade: return "Press Start 2P"
        case .glow: return "VT323"
        case .clean: return nil
        }
    }

    /// Family name for terminal body and subtitles. Nil uses the system
    /// monospaced face (SF Mono).
    var monoFontName: String? {
        switch self {
        case .arcade: return "JetBrains Mono"
        case .glow: return nil
        case .clean: return nil
        }
    }

    /// Corrects for cap height, so a given point size renders at the same optical
    /// size in every pairing. The bundled faces disagree wildly: VT323 draws caps
    /// at 0.56 em and Press Start 2P at 1.00 em, a 79% difference at the same
    /// nominal size. The reference is SF at 0.72 em.
    var chromeOpticalScale: CGFloat {
        switch self {
        case .arcade: return 0.72
        case .glow: return 1.29
        case .clean: return 1.00
        }
    }
}

/// Holds the active font pairing and vends themed fonts and colors. Injected as
/// an environment object so no view reaches for a raw color or font name.
final class ThemeManager: ObservableObject {
    @Published var pairing: FontPairing = .glow

    let palette = PotionPalette()

    init() {
        Self.registerBundledFonts()
    }

    func cycleFontPairing() {
        let all = FontPairing.allCases
        if let index = all.firstIndex(of: pairing) {
            pairing = all[(index + 1) % all.count]
        }
    }

    /// Display font for the wordmark and section headings. Sizes are corrected for
    /// cap height, so the same argument reads the same in every pairing. Intended
    /// for 12pt and up: the pixel faces lose their counters below that.
    func chromeFont(size: CGFloat) -> Font {
        if let name = pairing.chromeFontName {
            return .custom(name, fixedSize: size * pairing.chromeOpticalScale)
        }
        return .system(size: size, weight: .bold, design: .rounded)
    }

    /// Micro labels: tab titles, section eyebrows, badges. Always a UI face,
    /// never a pixel one. Small all-caps in a bitmap face is illegible at any
    /// point size the chrome can afford, so the theme does not offer the choice.
    /// Pair with `labelTracking`.
    func labelFont(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    /// Letterspacing for `labelFont` text set in caps, which needs the air.
    let labelTracking: CGFloat = 0.9

    /// Readable monospaced font for the subtitle bar and code snippets.
    func monoFont(size: CGFloat) -> Font {
        if let name = pairing.monoFontName {
            return .custom(name, fixedSize: size)
        }
        return .system(size: size, design: .monospaced)
    }

    private static func registerBundledFonts() {
        guard let dir = Bundle.main.url(forResource: "fonts", withExtension: nil),
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return
        }
        for url in files where url.pathExtension.lowercased() == "ttf" {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

/// Inline actions in the panels and the input bar. The system `.link` style
/// paints macOS accent blue, the one cold color in a warm plum interface, and it
/// carries more weight on the surface than the text it sits beside.
struct PotionLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        LinkLabel(configuration: configuration)
    }

    private struct LinkLabel: View {
        let configuration: PotionLinkButtonStyle.Configuration

        @EnvironmentObject private var theme: ThemeManager
        @State private var isHovering = false

        var body: some View {
            configuration.label
                .foregroundStyle(theme.palette.accentSoft)
                .opacity(opacity)
                .contentShape(Rectangle())
                .onHover { isHovering = $0 }
                .linkCursor()
                .animation(.easeOut(duration: 0.1), value: isHovering)
        }

        private var opacity: Double {
            if configuration.isPressed { return 0.55 }
            return isHovering ? 1.0 : 0.86
        }
    }
}

extension ButtonStyle where Self == PotionLinkButtonStyle {
    static var potionLink: PotionLinkButtonStyle { PotionLinkButtonStyle() }
}
