import SwiftUI

/// Witchy pixel glyphs on a 16 by 16 grid, drawn the same way as ``CatSprite``:
/// one character per pixel, no hand-drawn outline.
///
/// Each row is one string:
///   `.` empty · `B` body · `H` interior shade · `L` liquid or accent · `S` spark
///
/// The rim is not drawn. Any body pixel touching empty space is lit, which is
/// what makes the silhouettes read on dark chrome; an authored dark outline
/// vanishes against surfaces this deep. Editing a shape needs no outline pass.
enum WitchyGlyph: String, CaseIterable, Identifiable {
    case cauldron
    case broom
    case moon
    case sparkle
    case mushroom
    case crystal
    case candle
    case flask
    case moth
    case key

    var id: String { rawValue }

    static let size = 16

    var rows: [String] {
        switch self {
        case .cauldron: return Self.cauldronRows
        case .broom: return Self.broomRows
        case .moon: return Self.moonRows
        case .sparkle: return Self.sparkleRows
        case .mushroom: return Self.mushroomRows
        case .crystal: return Self.crystalRows
        case .candle: return Self.candleRows
        case .flask: return Self.flaskRows
        case .moth: return Self.mothRows
        case .key: return Self.keyRows
        }
    }

    private static let cauldronRows = [
        "................",
        "......S....S....",
        ".......S..S.....",
        "................",
        "..LLLLLLLLLLLL..",
        "..LLLLLLLLLLLL..",
        "..LSLLLLLLSLLL..",
        "..BBBBBBBBBBBB..",
        "...BHBBBBBBBB...",
        "...BHBBBBBBBB...",
        "...BBBBBBBBBB...",
        "....BBBBBBBB....",
        ".....BBBBBB.....",
        ".....B....B.....",
        "....BB....BB....",
        "................",
    ]

    private static let broomRows = [
        "...........BB...",
        "..........BBB...",
        ".........BBB....",
        "........BBB.....",
        ".......BBB......",
        "......BBB.......",
        ".....BBB........",
        "....BBB.........",
        "...BBBB.........",
        "..BBBBBB........",
        "..BLBLBLB.......",
        ".BLBLBLBLB......",
        ".BLBLBLBLB......",
        ".BLBLBLBLB......",
        "..BBBBBBB.......",
        "................",
    ]

    private static let moonRows = [
        "................",
        ".....BBBBB......",
        "...BBBBBBBBB....",
        "..BBBBBB........",
        "..BBBBB.........",
        ".BBBBB..........",
        ".BBHBB..........",
        ".BBHBB..........",
        ".BBHBB..........",
        ".BBHBB..........",
        ".BBBBB..........",
        "..BBBBB.........",
        "..BBBBBB........",
        "...BBBBBBBBB....",
        ".....BBBBB......",
        "................",
    ]

    private static let sparkleRows = [
        "................",
        ".......BB.......",
        ".......BB.......",
        ".......BB.......",
        "......BBBB......",
        ".....BBBBBB.....",
        "...BBBBBBBBBB...",
        ".BBBBBBBBBBBBBB.",
        ".BBBBBBBBBBBBBB.",
        "...BBBBBBBBBB...",
        ".....BBBBBB.....",
        "......BBBB......",
        ".......BB.......",
        ".......BB.......",
        ".......BB.......",
        "................",
    ]

    private static let mushroomRows = [
        "................",
        ".....BBBBBB.....",
        "...BBBBBBBBBB...",
        "..BBSBBBBSBBBB..",
        ".BBBBBBBBBBBBBB.",
        ".BBSBBBBBBBSBBB.",
        ".BBBBBBBBBBBBBB.",
        "..BBBBBBBBBBBB..",
        ".....HHHHHH.....",
        "......HHHH......",
        "......HHHH......",
        "......HHHH......",
        ".....HHHHHH.....",
        ".....HHHHHH.....",
        "................",
        "................",
    ]

    private static let crystalRows = [
        "................",
        ".......BB.......",
        "......HBBB......",
        ".....HHBBBB.....",
        "....HHBBBBBB....",
        "....HHBBBBBB....",
        "....HHBBBBBB....",
        "....HHBBBBBB....",
        "....HHBBBBBB....",
        "....HHBBBBBB....",
        ".....HBBBBB.....",
        "......HBBB......",
        ".......BB.......",
        "................",
        "................",
        "................",
    ]

    private static let candleRows = [
        "................",
        ".......S........",
        "......SLS.......",
        ".....SLLLS......",
        ".....SLLLS......",
        "......SLS.......",
        ".......S........",
        ".....BBBBB......",
        ".....BHBBB......",
        ".....BHBBB......",
        ".....BHBBB......",
        ".....BHBBB......",
        "....BBBBBBB.....",
        "....BBBBBBB.....",
        "................",
        "................",
    ]

    private static let flaskRows = [
        "................",
        "......BBBB......",
        "......B..B......",
        "......B..B......",
        ".....BB..BB.....",
        ".....B....B.....",
        "....B......B....",
        "...B........B...",
        "...BLLLLLLLLB...",
        "...BLLSLLLLLB...",
        "...BLLLLLLLLB...",
        "...BLLLLLLLLB...",
        "...BBLLLLLLBB...",
        "....BBBBBBBB....",
        "................",
        "................",
    ]

    private static let mothRows = [
        "................",
        "..B..........B..",
        "...B...BB...B...",
        "....B.BHHB.B....",
        ".BBBBBBHHBBBBBB.",
        "BBBBBBBHHBBBBBBB",
        "BBSBBBBHHBBBBSBB",
        "BBBBBBBHHBBBBBBB",
        ".BBBBBBHHBBBBBB.",
        "..BBBBBHHBBBBB..",
        "...BBBBHHBBBB...",
        "....BBBHHBBB....",
        ".......HH.......",
        "................",
        "................",
        "................",
    ]

    private static let keyRows = [
        "................",
        ".....BBBB.......",
        "....BB..BB......",
        "....BB..BB......",
        "....BB..BB......",
        ".....BBBB.......",
        "......BB........",
        "......BB........",
        "......BB........",
        "......BBB.......",
        "......BB........",
        "......BBB.......",
        "......BB........",
        "......BB........",
        "................",
        "................",
    ]
}

/// Draws a ``WitchyGlyph`` in the active skin's colors. Mirrors ``PixelCat``:
/// a Canvas of filled cells with the rim resolved per pixel.
struct PixelGlyph: View {
    let glyph: WitchyGlyph
    var cell: CGFloat = 3

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Canvas { context, _ in
            let grid = glyph.rows.map(Array.init)
            for (row, characters) in grid.enumerated() {
                for (column, character) in characters.enumerated() where character != "." {
                    let rect = CGRect(
                        x: CGFloat(column) * cell,
                        y: CGFloat(row) * cell,
                        width: cell + 0.3,
                        height: cell + 0.3
                    )
                    let fill = color(for: character, grid: grid, row: row, column: column)
                    context.fill(Path(rect), with: .color(fill))
                }
            }
        }
        .frame(
            width: CGFloat(WitchyGlyph.size) * cell,
            height: CGFloat(WitchyGlyph.size) * cell
        )
        .accessibilityHidden(true)
    }

    private func color(for character: Character, grid: [[Character]], row: Int, column: Int) -> Color {
        if character == "B", isEdge(grid: grid, row: row, column: column) {
            return theme.palette.rim
        }
        switch character {
        case "H": return theme.palette.cardBackgroundRaised
        case "L": return theme.palette.accentSoft
        case "S": return theme.palette.sparkle
        default: return theme.palette.accent
        }
    }

    /// True when the cell touches empty space, which is what gets lit.
    private func isEdge(grid: [[Character]], row: Int, column: Int) -> Bool {
        for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            let r = row + dr, c = column + dc
            guard r >= 0, r < grid.count, c >= 0, c < grid[r].count else { return true }
            if grid[r][c] == "." { return true }
        }
        return false
    }
}
