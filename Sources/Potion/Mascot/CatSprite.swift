import PotionCore
import SwiftUI

/// The mascot as pixel art on a 20 by 14 grid.
///
/// Each row is one string, one character per pixel:
///   `.` empty · `K` fur · `E` eye · `W` eye highlight · `N` nose
///   `M` whisker or mouth · `G` happy eyes
///
/// The rim light is not drawn by hand. Any fur pixel touching empty space is
/// lit, so the silhouette can be edited without redrawing the outline.
enum CatSprite {
    static let width = 20
    static let height = 14

    /// The sprite for a state. Blinking closes the eyes of any open-eyed frame.
    static func rows(for state: MascotState, blinking: Bool) -> [String] {
        switch state {
        case .idle:
            return face(eyes: closed)
        case .typing:
            return face(eyes: blinking ? closed : open)
        case .running:
            return face(eyes: blinking ? closed : narrow)
        case .success:
            return face(eyes: happy)
        case .failure:
            return face(eyes: blinking ? closed : open, earsUp: false, overrides: [
                4: ".KKKKKKKKKKKKKKKKKK.",  // ears flattened out to the sides
                11: "....KKKKMMMMKKKK....", // a small, gentle mouth
            ])
        }
    }

    // MARK: Frames

    private static let open = [
        "...KKWEEKKKKWEEKK...",
        "...KKEEEKKKKEEEKK...",
        "...KKEEEKKKKEEEKK...",
    ]
    private static let closed = [
        "...KKKKKKKKKKKKKK...",
        "...KKKKKKKKKKKKKK...",
        "...KKEEEKKKKEEEKK...",
    ]
    private static let narrow = [
        "...KKKKKKKKKKKKKK...",
        "...KKKEEKKKKEEKKK...",
        "...KKKEEKKKKEEKKK...",
    ]
    private static let happy = [
        "...KKKKKKKKKKKKKK...",
        "...KKKGKKKKKKGKKK...",
        "...KKGKGKKKKGKGKK...",
    ]

    /// Assembles a frame: ears, head, the given eyes, whiskers above and below
    /// the nose.
    private static func face(eyes: [String], earsUp: Bool = true, overrides: [Int: String] = [:]) -> [String] {
        var rows = [String](repeating: "....................", count: height)
        if earsUp {
            rows[0] = "....K..........K...."
            rows[1] = "....KK........KK...."
            rows[2] = "....KKK......KKK...."
        }
        rows[3] = "....KKKKKKKKKKKK...."
        rows[4] = "...KKKKKKKKKKKKKK..."
        rows[5] = eyes[0]
        rows[6] = eyes[1]
        rows[7] = eyes[2]
        rows[8] = ".MMKKKKKKKKKKKKKKMM."
        rows[9] = "...KKKKKKNNKKKKKK..."
        rows[10] = ".MMKKKKKKKKKKKKKKMM."
        rows[11] = "....KKKKKKKKKKKK...."
        rows[12] = ".....KKKKKKKKKK....."
        for (index, row) in overrides {
            rows[index] = row
        }
        return rows
    }
}

/// Draws a ``CatSprite`` frame, computing the rim light from the silhouette.
struct PixelCat: View {
    let rows: [String]
    let cell: CGFloat

    @EnvironmentObject private var theme: ThemeManager

    private var furColor: Color { Color(red: 0.06, green: 0.04, blue: 0.09) }

    var body: some View {
        Canvas { context, _ in
            let grid = rows.map(Array.init)
            for (r, row) in grid.enumerated() {
                for (c, character) in row.enumerated() where character != "." {
                    let rect = CGRect(
                        x: CGFloat(c) * cell,
                        y: CGFloat(r) * cell,
                        width: cell + 0.5,
                        height: cell + 0.5
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
