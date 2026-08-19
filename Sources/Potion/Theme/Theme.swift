import AppKit
import CoreText
import SwiftUI

/// Builds a color from HSL. SwiftUI offers HSB, which does not give an even
/// lightness ladder: the same brightness step reads as a different distance at
/// different saturations. The surface rungs are specified in HSL so every skin
/// gets the same perceptual spacing regardless of its hue.
private func hsl(_ hue: Double, _ saturation: Double, _ lightness: Double) -> Color {
    let chroma = (1 - abs(2 * lightness - 1)) * saturation
    let sector = hue / 60
    let second = chroma * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
    let base = lightness - chroma / 2
    let rgb: (Double, Double, Double)
    switch sector {
    case ..<1: rgb = (chroma, second, 0)
    case ..<2: rgb = (second, chroma, 0)
    case ..<3: rgb = (0, chroma, second)
    case ..<4: rgb = (0, second, chroma)
    case ..<5: rgb = (second, 0, chroma)
    default: rgb = (chroma, 0, second)
    }
    return Color(red: rgb.0 + base, green: rgb.1 + base, blue: rgb.2 + base)
}

private typealias RGB = (r: Double, g: Double, b: Double)

private func color(_ c: RGB) -> Color { Color(red: c.r, green: c.g, blue: c.b) }

/// Mixes toward white. Used for rim, which is always the accent one step up.
private func lightened(_ c: RGB, _ amount: Double) -> Color {
    Color(red: c.r + (1 - c.r) * amount,
          green: c.g + (1 - c.g) * amount,
          blue: c.b + (1 - c.b) * amount)
}

/// How a skin marks the selected section in the companion panel. Color alone is
/// not enough to carry selection, so every skin also changes its shape.
enum TabSignature {
    case rule
    case bracket
    case moonPhase
    case star
    case ribbon
}

enum AppearanceMode: String, CaseIterable, Identifiable, Codable {
    case dark
    case light

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark (Candlelit)"
        case .light: return "Light (Parchment)"
        }
    }
}

/// A complete look: surfaces, accents, motif, and the shape of selection.
///
/// Surfaces and text are derived rather than listed. Each skin supplies a hue
/// and a saturation, and the ladder below does the rest, so no skin can drift
/// off the spacing or fall below AA. See `.interface-design/system.md`.
enum Skin: String, CaseIterable, Identifiable, Codable {
    case obsidian
    case bloodMoon
    case emerald
    case nebula
    case cauldron
    case apothecary
    case moss
    case nocturne
    case blush
    case alchemist

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .obsidian: return "Void Obsidian & Moonstone"
        case .bloodMoon: return "Blood Moon & Crimson"
        case .emerald: return "Shadow Emerald & Poison"
        case .nebula: return "Celestial Nebula & Amethyst"
        case .cauldron: return "Cauldron"
        case .apothecary: return "Apothecary"
        case .moss: return "Moss & Moonlight"
        case .nocturne: return "Nocturne"
        case .blush: return "Blush Grimoire"
        case .alchemist: return "Alchemist"
        }
    }

    var blurb: String {
        switch self {
        case .obsidian: return "Midnight teal, obsidian dark, and glowing moonstone cyan."
        case .bloodMoon: return "Deep eclipse maroon, crimson ruby, and warm copper."
        case .emerald: return "Deep forest velvet, luminous emerald, and jade sparkle."
        case .nebula: return "Rich royal violet, electric amethyst, and cosmic gold."
        case .cauldron: return "Plum and rose. The original."
        case .apothecary: return "Ink blue and brass. Reads as a tool."
        case .moss: return "Forest dark and sage. Herbal, not spooky."
        case .nocturne: return "Indigo and lilac. Closest to a plain dark terminal."
        case .blush: return "Warm brown and blush. The most book-like."
        case .alchemist: return "Warm plum, rose, and brass detailing."
        }
    }

    var signature: TabSignature {
        switch self {
        case .obsidian: return .moonPhase
        case .bloodMoon: return .ribbon
        case .emerald: return .bracket
        case .nebula: return .star
        case .cauldron: return .rule
        case .apothecary: return .bracket
        case .moss: return .moonPhase
        case .nocturne: return .star
        case .blush: return .ribbon
        case .alchemist: return .bracket
        }
    }

    /// The glyphs this skin draws in empty states, strongest first.
    var motif: [WitchyGlyph] {
        switch self {
        case .obsidian: return [.crystal, .moon, .sparkle]
        case .bloodMoon: return [.cauldron, .candle, .key]
        case .emerald: return [.flask, .mushroom, .moth]
        case .nebula: return [.sparkle, .crystal, .broom]
        case .cauldron: return [.cauldron, .sparkle, .moon]
        case .apothecary: return [.flask, .key, .candle]
        case .moss: return [.mushroom, .moth, .moon]
        case .nocturne: return [.sparkle, .crystal, .moon]
        case .blush: return [.broom, .candle, .key]
        case .alchemist: return [.cauldron, .flask, .candle]
        }
    }

    // MARK: Derivation

    private static let surfaceLightnessDark: [Double] = [0.075, 0.115, 0.155, 0.235, 0.300]
    private static let surfaceLightnessLight: [Double] = [0.97, 0.93, 0.88, 0.82, 0.76]

    private static let textLightnessDark: [Double] = [0.88, 0.78, 0.70, 0.58]
    private static let textLightnessLight: [Double] = [0.12, 0.26, 0.38, 0.52]

    private static let textSaturation: Double = 0.12

    private var hue: Double {
        switch self {
        case .obsidian: return 195
        case .bloodMoon: return 352
        case .emerald: return 160
        case .nebula: return 275
        case .cauldron: return 268
        case .apothecary: return 214
        case .moss: return 148
        case .nocturne: return 252
        case .blush: return 348
        case .alchemist: return 322
        }
    }

    private var surfaceSaturation: Double {
        switch self {
        case .obsidian: return 0.35
        case .bloodMoon: return 0.38
        case .emerald: return 0.36
        case .nebula: return 0.36
        case .cauldron: return 0.34
        case .apothecary: return 0.36
        case .moss: return 0.30
        case .nocturne: return 0.30
        case .blush: return 0.28
        case .alchemist: return 0.26
        }
    }

    private var accentRGB: RGB {
        switch self {
        case .obsidian: return (0.35, 0.90, 0.95)
        case .bloodMoon: return (1.00, 0.32, 0.42)
        case .emerald: return (0.25, 0.92, 0.65)
        case .nebula: return (0.82, 0.48, 1.00)
        case .cauldron: return (1.00, 0.40, 0.70)
        case .apothecary: return (0.91, 0.69, 0.29)
        case .moss: return (0.56, 0.86, 0.63)
        case .nocturne: return (0.73, 0.65, 1.00)
        case .blush: return (0.95, 0.63, 0.71)
        case .alchemist: return (0.96, 0.56, 0.69)
        }
    }

    /// The second accent: links, the working directory, glyph fills.
    private var accentSoftRGB: RGB {
        switch self {
        case .obsidian: return (0.70, 0.85, 1.00)
        case .bloodMoon: return (0.95, 0.72, 0.45)
        case .emerald: return (0.78, 0.92, 0.75)
        case .nebula: return (0.95, 0.82, 0.48)
        case .cauldron: return (0.82, 0.71, 1.00)
        case .apothecary: return (0.62, 0.77, 0.91)
        case .moss: return (0.90, 0.89, 0.71)
        case .nocturne: return (0.87, 0.89, 0.96)
        case .blush: return (0.94, 0.87, 0.78)
        case .alchemist: return (0.91, 0.69, 0.29)
        }
    }

    /// Highlights inside the pixel glyphs: bubbles, flames, wing spots.
    private var sparkleRGB: RGB {
        switch self {
        case .obsidian: return (0.90, 0.95, 1.00)
        case .bloodMoon: return (1.00, 0.88, 0.55)
        case .emerald: return (0.92, 0.98, 0.70)
        case .nebula: return (1.00, 0.94, 0.72)
        case .cauldron: return (1.00, 0.87, 0.47)
        case .apothecary: return (0.96, 0.91, 0.76)
        case .moss: return (0.96, 0.94, 0.78)
        case .nocturne: return (1.00, 0.96, 0.80)
        case .blush: return (0.94, 0.87, 0.78)
        case .alchemist: return (0.94, 0.87, 0.78)
        }
    }

    /// Green reads as success everywhere except on the green skin, where it
    /// would sit on its own hue. Moss lifts it to a pale mint instead.
    private var successRGB: RGB {
        (self == .moss || self == .emerald) ? (0.80, 0.98, 0.87) : (0.44, 0.91, 0.70)
    }

    var palette: PotionPalette {
        palette(mode: .dark)
    }

    func palette(mode: AppearanceMode) -> PotionPalette {
        let isLight = mode == .light
        let surfaceLightnessList = isLight ? Self.surfaceLightnessLight : Self.surfaceLightnessDark
        let textLightnessList = isLight ? Self.textLightnessLight : Self.textLightnessDark
        let satMult = isLight ? 0.18 : surfaceSaturation

        let surfaces = surfaceLightnessList.enumerated().map { index, lightness in
            hsl(hue, satMult * (1 - Double(index) * 0.05), lightness)
        }
        let text = textLightnessList.map { hsl(hue, Self.textSaturation, $0) }

        let rawAccent = color(accentRGB)
        let rawAccentSoft = color(accentSoftRGB)
        let accent = isLight ? hsl(hue, 0.75, 0.35) : rawAccent
        let accentSoft = isLight ? hsl(hue, 0.65, 0.40) : rawAccentSoft

        return PotionPalette(
            terminalBackground: surfaces[0],
            panelBackground: surfaces[1],
            windowChrome: surfaces[2],
            cardBackground: surfaces[3],
            cardBackgroundRaised: surfaces[4],
            accent: accent,
            accentSoft: accentSoft,
            rim: isLight ? accent.opacity(0.7) : lightened(accentRGB, 0.22),
            sparkle: isLight ? hsl(hue, 0.85, 0.30) : color(sparkleRGB),
            textPrimary: text[0],
            textSecondary: text[1],
            textTertiary: text[2],
            textMuted: text[3],
            terminalForeground: isLight ? hsl(hue, Self.textSaturation, 0.10) : hsl(hue, Self.textSaturation, 0.90),
            success: isLight ? Color(red: 0.15, green: 0.55, blue: 0.32) : color(successRGB),
            running: isLight ? Color(red: 0.78, green: 0.48, blue: 0.10) : Color(red: 1.00, green: 0.79, blue: 0.42),
            failure: isLight ? Color(red: 0.78, green: 0.20, blue: 0.28) : Color(red: 1.00, green: 0.50, blue: 0.61),
            divider: isLight ? Color.black.opacity(0.12) : Color.white.opacity(0.14)
        )
    }
}

/// The resolved colors for one skin. Nothing downstream hardcodes a value.
///
/// Surfaces are a five rung ladder on a single hue, lightness only. The terminal
/// is the darkest well and each layer of chrome steps up from it, so depth comes
/// from the ladder rather than from borders.
struct PotionPalette: Equatable {
    let terminalBackground: Color
    let panelBackground: Color
    let windowChrome: Color
    let cardBackground: Color
    let cardBackgroundRaised: Color

    let accent: Color
    let accentSoft: Color
    let rim: Color
    let sparkle: Color

    // Four levels. Each clears WCAG AA on the surfaces it is used on; `textMuted`
    // is for disabled controls only, which 1.4.3 exempts.
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textMuted: Color

    /// Held under `textPrimary`: the well is the darkest surface in the app and
    /// pure white on it is tiring to read for as long as a terminal gets read.
    let terminalForeground: Color

    let success: Color
    let running: Color
    let failure: Color

    let divider: Color

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

/// How large the interface text runs. Every font the theme vends is multiplied
/// by this, so one control governs the whole window rather than the reader
/// hunting for the one label that stayed small.
enum TextSize: String, CaseIterable, Identifiable {
    case compact
    case standard
    case large
    case largest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .standard: return "Standard"
        case .large: return "Large"
        case .largest: return "Largest"
        }
    }

    var scale: CGFloat {
        switch self {
        case .compact: return 0.92
        case .standard: return 1.00
        case .large: return 1.15
        case .largest: return 1.32
        }
    }
}

/// Holds the active skin and font pairing and vends themed fonts and colors.
/// Injected as an environment object so no view reaches for a raw color or font
/// name. Both choices persist across launches.
final class ThemeManager: ObservableObject {
    private enum Key {
        static let skin = "appearance.skin"
        static let pairing = "appearance.fontPairing"
        static let textSize = "appearance.textSize"
        static let mode = "appearance.mode"
    }

    @Published var skin: Skin {
        didSet { UserDefaults.standard.set(skin.rawValue, forKey: Key.skin) }
    }

    @Published var mode: AppearanceMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Key.mode) }
    }

    @Published var pairing: FontPairing {
        didSet { UserDefaults.standard.set(pairing.rawValue, forKey: Key.pairing) }
    }

    @Published var textSize: TextSize {
        didSet { UserDefaults.standard.set(textSize.rawValue, forKey: Key.textSize) }
    }

    var palette: PotionPalette { skin.palette(mode: mode) }

    init() {
        let defaults = UserDefaults.standard
        skin = defaults.string(forKey: Key.skin).flatMap(Skin.init(rawValue:)) ?? .obsidian
        mode = defaults.string(forKey: Key.mode).flatMap(AppearanceMode.init(rawValue:)) ?? .dark
        pairing = defaults.string(forKey: Key.pairing).flatMap(FontPairing.init(rawValue:)) ?? .glow
        textSize = defaults.string(forKey: Key.textSize).flatMap(TextSize.init(rawValue:)) ?? .standard
        Self.registerBundledFonts()
    }

    func toggleMode() {
        mode = (mode == .dark) ? .light : .dark
    }

    func cycleFontPairing() {
        let all = FontPairing.allCases
        if let index = all.firstIndex(of: pairing) {
            pairing = all[(index + 1) % all.count]
        }
    }

    func cycleSkin() {
        let all = Skin.allCases
        if let index = all.firstIndex(of: skin) {
            skin = all[(index + 1) % all.count]
        }
    }

    /// Display font for the wordmark and section headings. Sizes are corrected for
    /// cap height, so the same argument reads the same in every pairing. Intended
    /// for 12pt and up: the pixel faces lose their counters below that.
    func chromeFont(size: CGFloat) -> Font {
        let size = scaled(size)
        if let name = pairing.chromeFontName {
            return .custom(name, fixedSize: size * pairing.chromeOpticalScale)
        }
        return .system(size: size, weight: .bold, design: .rounded)
    }

    /// Everything the interface reads: body copy, metadata, captions, code.
    /// Every call site goes through here so `textSize` reaches all of it. The
    /// app used to mix these with raw `.caption` and `.callout`, which is why
    /// no single control could reach the whole window.
    func font(_ size: CGFloat, weight: Font.Weight = .regular, mono: Bool = false) -> Font {
        if mono, let name = pairing.monoFontName {
            return .custom(name, fixedSize: scaled(size))
        }
        return .system(size: scaled(size), weight: weight, design: mono ? .monospaced : .default)
    }

    /// Point size after the reader's text-size choice.
    func scaled(_ size: CGFloat) -> CGFloat { (size * textSize.scale).rounded() }

    /// Section headings inside the panels. A UI face, not a pixel one: a heading
    /// names content, and the pixel identity is carried by the wordmark, the
    /// mascot, and the motif glyphs without also taxing the text that has to be
    /// read. Title case, so no tracking.
    func headingFont(size: CGFloat) -> Font {
        .system(size: scaled(size), weight: .semibold)
    }

    /// Micro labels: tab titles, section eyebrows, badges. Always a UI face,
    /// never a pixel one. Small all-caps in a bitmap face is illegible at any
    /// point size the chrome can afford, so the theme does not offer the choice.
    /// Pair with `labelTracking`.
    ///
    /// Medium, not semibold. Light-on-dark text renders optically heavier than
    /// the same weight on a light background, so a semibold label at this size
    /// fills in its own counters and turns into a smudge.
    func labelFont(size: CGFloat) -> Font {
        .system(size: scaled(size), weight: .medium)
    }

    /// Letterspacing for `labelFont` text set in caps, which needs the air.
    let labelTracking: CGFloat = 0.9

    /// Readable monospaced font for the subtitle bar and code snippets.
    func monoFont(size: CGFloat) -> Font {
        font(size, mono: true)
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

extension Color {
    /// Mixes toward another color in sRGB.
    ///
    /// macOS 14 has no color mixing of its own and the palette vends finished
    /// colors, so shades are derived here. Everything mixed comes from the
    /// active skin, which is what keeps derived surfaces on palette when the
    /// skin changes underneath them.
    func mixed(with other: Color, amount: Double) -> Color {
        guard let base = NSColor(self).usingColorSpace(.sRGB),
              let target = NSColor(other).usingColorSpace(.sRGB)
        else { return self }

        let t = CGFloat(min(max(amount, 0), 1))
        return Color(
            red: Double(base.redComponent + (target.redComponent - base.redComponent) * t),
            green: Double(base.greenComponent + (target.greenComponent - base.greenComponent) * t),
            blue: Double(base.blueComponent + (target.blueComponent - base.blueComponent) * t)
        )
    }
}
