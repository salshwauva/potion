import PotionCore
import SwiftUI

/// The mascot as pixel art on a 40 by 30 grid. Drawing at this resolution keeps
/// the cat a comfortable size while each pixel, and so the pink outline, stays
/// thin.
///
/// Each row is one string, one character per pixel:
///   `.` empty · `K` fur · `E` eye · `W` eye highlight · `N` nose
///   `M` whisker or mouth · `G` happy eyes
///
/// The rim light is not drawn by hand. Any fur pixel touching empty space is
/// lit, so the silhouette can be edited without redrawing the outline. The
/// frames are generated from a small drawing script; see the scratch tools.
enum CatSprite {
    static let width = 40
    static let height = 30

    /// The sprite for a state. Blinking closes the eyes of the open-eyed frames.
    static func rows(for state: MascotState, blinking: Bool) -> [String] {
        switch state {
        case .idle: return idle
        case .typing: return blinking ? idle : typing
        case .running: return blinking ? idle : running
        case .success: return success
        case .failure: return failure
        }
    }

    private static let idle: [String] = [
        "........................................",
        "........................................",
        "...........K................K...........",
        "...........KK..............KK...........",
        "..........KKK..............KKK..........",
        "..........KKKK............KKKK..........",
        "..........KKKKK...........KKKKK.........",
        ".........KKKKKK..........KKKKKK.........",
        ".........KKKKKKK........KKKKKKK.........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKEEEEEKKKKKKEEEEEKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "....MMMMKKKKKKKKKKKKKKKKKKKKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "....MMMMKKKKKKKKKKKKKKKKKKKKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "..........KKKKKKKKKKKKKKKKKKKK..........",
        "...........KKKKKKKKKKKKKKKKKK...........",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
    ]

    private static let typing: [String] = [
        "........................................",
        "........................................",
        "...........K................K...........",
        "...........KK..............KK...........",
        "..........KKK..............KKK..........",
        "..........KKKK............KKKK..........",
        "..........KKKKK...........KKKKK.........",
        ".........KKKKKK..........KKKKKK.........",
        ".........KKKKKKK........KKKKKKK.........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKEEEKKKKKKKKEEEKKKKK........",
        "........KKKKEWEEEKKKKKKEWEEEKKKK........",
        "........KKKKEEEEEKKKKKKEEEEEKKKK........",
        "........KKKKEEEEEKKKKKKEEEEEKKKK........",
        "....MMMMKKKKKEEEKKKKKKKKEEEKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "....MMMMKKKKKKKKKKKKKKKKKKKKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "..........KKKKKKKKKKKKKKKKKKKK..........",
        "...........KKKKKKKKKKKKKKKKKK...........",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
    ]

    private static let running: [String] = [
        "........................................",
        "........................................",
        "...........K................K...........",
        "...........KK..............KK...........",
        "..........KKK..............KKK..........",
        "..........KKKK............KKKK..........",
        "..........KKKKK...........KKKKK.........",
        ".........KKKKKK..........KKKKKK.........",
        ".........KKKKKKK........KKKKKKK.........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKEEEEEKKKKKKEEEEEKKKK........",
        "........KKKKEEEEEKKKKKKEEEEEKKKK........",
        "....MMMMKKKKKKKKKKKKKKKKKKKKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "....MMMMKKKKKKKKKKKKKKKKKKKKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "..........KKKKKKKKKKKKKKKKKKKK..........",
        "...........KKKKKKKKKKKKKKKKKK...........",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
    ]

    private static let success: [String] = [
        "........................................",
        "........................................",
        "...........K................K...........",
        "...........KK..............KK...........",
        "..........KKK..............KKK..........",
        "..........KKKK............KKKK..........",
        "..........KKKKK...........KKKKK.........",
        ".........KKKKKK..........KKKKKK.........",
        ".........KKKKKKK........KKKKKKK.........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKGKKKGKKKKKKGKKKGKKKK........",
        "........KKKKKGKGKKKKKKKKGKGKKKKK........",
        "........KKKKKKGKKKKKKKKKKGKKKKKK........",
        "....MMMMKKKKKKKKKKKKKKKKKKKKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "....MMMMKKKKKKKKKKKKKKKKKKKKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "..........KKKKKKKKKKKKKKKKKKKK..........",
        "...........KKKKKKKKKKKKKKKKKK...........",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
    ]

    private static let failure: [String] = [
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
        "...........KKKKKKKKKKKKKKKKKK...........",
        "..........KKKKKKKKKKKKKKKKKKKK..........",
        ".........KKKKKKKKKKKKKKKKKKKKKK.........",
        "....KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK....",
        "....KKKKKKKKKEEEKKKKKKKKEEEKKKKKKKKK....",
        "....KKKKKKKKEWEEEKKKKKKEWEEEKKKKKKKK....",
        "....KKKKKKKKEEEEEKKKKKKEEEEEKKKKKKKK....",
        "........KKKKEEEEEKKKKKKEEEEEKKKK........",
        "....MMMMKKKKKEEEKKKKKKKKEEEKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "........KKKKKKKKKKKNNKKKKKKKKKKK........",
        "....MMMMKKKKKKKKKKKKKKKKKKKKKKKKMMMM....",
        "........KKKKKKKKKKKKKKKKKKKKKKKK........",
        ".........KKKKKKKKMMMMMMKKKKKKKK.........",
        "..........KKKKKKKKKKKKKKKKKKKK..........",
        "...........KKKKKKKKKKKKKKKKKK...........",
        "........................................",
        "........................................",
        "........................................",
        "........................................",
    ]
}

/// Draws a ``CatSprite`` frame, computing the rim light from the silhouette.
struct PixelCat: View {
    let rows: [String]
    let cell: CGFloat

    @EnvironmentObject private var theme: ThemeManager

    /// The cat stays a black cat in every skin, but it is the skin's black: the
    /// terminal well, which is the darkest rung. A fixed plum-black read as a
    /// hole punched in the panel once the green and brown skins existed.
    private var furColor: Color { theme.palette.terminalBackground }

    var body: some View {
        Canvas { context, _ in
            let grid = rows.map(Array.init)
            for (r, row) in grid.enumerated() {
                for (c, character) in row.enumerated() where character != "." {
                    let rect = CGRect(
                        x: CGFloat(c) * cell,
                        y: CGFloat(r) * cell,
                        width: cell + 0.3,
                        height: cell + 0.3
                    )
                    context.fill(Path(rect), with: .color(color(for: character, grid: grid, r: r, c: c)))
                }
            }
        }
        .frame(width: CGFloat(CatSprite.width) * cell, height: CGFloat(CatSprite.height) * cell)
        .accessibilityHidden(true)
    }

    private func color(for character: Character, grid: [[Character]], r: Int, c: Int) -> Color {
        switch character {
        case "E": return theme.palette.accentSoft
        case "W": return .white
        case "N": return theme.palette.accent
        case "M": return theme.palette.textSecondary
        case "G": return theme.palette.success
        default:
            return isEdge(grid, r, c) ? theme.palette.rim : furColor
        }
    }

    /// A fur pixel is lit when any of its four neighbors is empty.
    private func isEdge(_ grid: [[Character]], _ r: Int, _ c: Int) -> Bool {
        !filled(grid, r - 1, c) || !filled(grid, r + 1, c)
            || !filled(grid, r, c - 1) || !filled(grid, r, c + 1)
    }

    private func filled(_ grid: [[Character]], _ r: Int, _ c: Int) -> Bool {
        guard r >= 0, r < grid.count else { return false }
        let row = grid[r]
        guard c >= 0, c < row.count else { return false }
        return row[c] != "."
    }
}
