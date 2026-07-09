import CoreText
import SwiftUI

/// The Potion palette. Colors are tokens so nothing downstream hardcodes a value.
/// The witchy colors live in the chrome, panels, and accents. The terminal's own
/// text area uses a separate, conventional, high-legibility scheme (see
/// `TerminalPalette`) because readability there is load-bearing.
struct PotionPalette {
    // Chrome and surfaces (deep plum and indigo).
    let windowChrome = Color(red: 0.14, green: 0.09, blue: 0.20)
    let panelBackground = Color(red: 0.11, green: 0.08, blue: 0.17)
    let cardBackground = Color(red: 0.20, green: 0.15, blue: 0.29)
    let cardBackgroundRaised = Color(red: 0.24, green: 0.18, blue: 0.34)

    // Accents (pink, magenta, lavender).
    let accent = Color(red: 1.00, green: 0.31, blue: 0.64)
    let accentSoft = Color(red: 0.79, green: 0.66, blue: 1.00)
    let rim = Color(red: 1.00, green: 0.44, blue: 0.71)

    // Text, tuned for WCAG AA on the plum surfaces.
    let textPrimary = Color(red: 0.95, green: 0.92, blue: 1.00)
    let textSecondary = Color(red: 0.73, green: 0.65, blue: 0.85)
    let textTertiary = Color(red: 0.54, green: 0.47, blue: 0.66)

    // Status.
    let success = Color(red: 0.36, green: 0.89, blue: 0.65)
    let running = Color(red: 1.00, green: 0.78, blue: 0.36)
    let failure = Color(red: 1.00, green: 0.42, blue: 0.54)

    let divider = Color.white.opacity(0.12)
}

/// A pairing of a display face for chrome and a readable face for body and
/// terminal text. The pixel faces are never used for the terminal body or
/// subtitles; legibility comes first there.
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

    /// Display font for chrome, headings, and badges.
    func chromeFont(size: CGFloat) -> Font {
        if let name = pairing.chromeFontName {
            return .custom(name, fixedSize: size)
        }
        return .system(size: size, weight: .bold, design: .rounded)
    }

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
