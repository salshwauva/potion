import SwiftUI

/// The Appearance pane behind Command-comma. Skins are shown as their own
/// swatches rather than a list of names, because the choice is a visual one and
/// a name in a popup says nothing about what the window will look like.
struct AppearanceSettings: View {
    @EnvironmentObject private var theme: ThemeManager

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section("Appearance mode") {
                    Picker("Appearance mode", selection: $theme.mode) {
                        ForEach(AppearanceMode.allCases) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Divider()

                section("Skin") {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Skin.allCases) { skin in
                            SkinTile(skin: skin, mode: theme.mode, isSelected: theme.skin == skin) {
                                theme.skin = skin
                            }
                        }
                    }
                    Text(theme.skin.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }

                Divider()

                section("Text size") {
                    Picker("Text size", selection: $theme.textSize) {
                        ForEach(TextSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Text("Scales every label, caption, and code sample in the window, including the composer. The terminal's own text is set by its font.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                section("Type") {
                    Picker("Font pairing", selection: $theme.pairing) {
                        ForEach(FontPairing.allCases) { pairing in
                            Text(pairing.displayName).tag(pairing)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Text("Arcade and Glow set the wordmark and headings in a pixel face. Body text, subtitles, and the terminal never use one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
        }
        .frame(width: 520, height: 460)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

/// One skin as a miniature of the real window: chrome bar, terminal well, a
/// card, and the skin's own selection mark and motif glyph.
private struct SkinTile: View {
    let skin: Skin
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    private var palette: PotionPalette { skin.palette(mode: mode) }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                preview
                Text(skin.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .background(RoundedRectangle(cornerRadius: 9).fill(Color.primary.opacity(isHovering ? 0.06 : 0)))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.14),
                                  lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(skin.displayName)
        .accessibilityHint(skin.blurb)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var preview: some View {
        VStack(spacing: 0) {
            HStack(spacing: 3) {
                Circle().fill(palette.accent).frame(width: 4, height: 4)
                Rectangle().fill(palette.textSecondary).frame(width: 22, height: 2)
                Spacer()
            }
            .padding(.horizontal, 6)
            .frame(height: 14)
            .frame(maxWidth: .infinity)
            .background(palette.windowChrome)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    Rectangle().fill(palette.terminalForeground).frame(width: 30, height: 2)
                    Rectangle().fill(palette.textTertiary).frame(width: 20, height: 2)
                    Spacer()
                }
                .padding(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(palette.terminalBackground)

                VStack(spacing: 4) {
                    tabStrip
                    RoundedRectangle(cornerRadius: 3)
                        .fill(palette.cardBackground)
                        .frame(height: 14)
                    Spacer(minLength: 0)
                }
                .padding(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.panelBackground)
                .overlay(alignment: .bottomTrailing) {
                    PixelGlyphPreview(glyph: skin.motif[0], palette: palette, cell: 1.6)
                        .padding(4)
                }
            }
            .frame(height: 58)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8))
    }

    /// The three sections, with the skin's mark on the active one.
    private var tabStrip: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index == 0 ? palette.cardBackground : .clear)
                    if index == 0 { mark }
                }
                .frame(height: 10)
            }
        }
    }

    @ViewBuilder
    private var mark: some View {
        switch skin.signature {
        case .rule:
            VStack { Spacer(); Rectangle().fill(palette.accent).frame(height: 1.5) }
        case .bracket:
            HStack {
                Rectangle().fill(palette.accent).frame(width: 1.5)
                Spacer()
                Rectangle().fill(palette.accent).frame(width: 1.5)
            }
            .padding(.vertical, 1.5)
        case .moonPhase:
            VStack {
                Spacer()
                Circle()
                    .fill(palette.accent)
                    .frame(width: 4, height: 4)
                    .overlay(Circle().fill(palette.cardBackground).frame(width: 3.4).offset(x: 1.3))
                    .clipShape(Circle())
                    .padding(.bottom, 1)
            }
        case .star:
            VStack {
                HStack { Spacer(); Text("✦").font(.system(size: 5)).foregroundStyle(palette.accent) }
                Spacer()
            }
            .padding(1.5)
        case .ribbon:
            VStack { Spacer(); Rectangle().fill(palette.accent).frame(height: 2.5) }
        }
    }
}

/// The glyph renderer without the environment, so a tile can draw a skin that is
/// not the active one.
private struct PixelGlyphPreview: View {
    let glyph: WitchyGlyph
    let palette: PotionPalette
    let cell: CGFloat

    var body: some View {
        Canvas { context, _ in
            let grid = glyph.rows.map(Array.init)
            for (row, characters) in grid.enumerated() {
                for (column, character) in characters.enumerated() where character != "." {
                    let rect = CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell,
                                      width: cell + 0.3, height: cell + 0.3)
                    context.fill(Path(rect), with: .color(color(character, grid, row, column)))
                }
            }
        }
        .frame(width: CGFloat(WitchyGlyph.size) * cell, height: CGFloat(WitchyGlyph.size) * cell)
        .accessibilityHidden(true)
    }

    private func color(_ character: Character, _ grid: [[Character]], _ row: Int, _ column: Int) -> Color {
        if character == "B", isEdge(grid, row, column) { return palette.rim }
        switch character {
        case "H": return palette.cardBackgroundRaised
        case "L": return palette.accentSoft
        case "S": return palette.sparkle
        default: return palette.accent
        }
    }

    private func isEdge(_ grid: [[Character]], _ row: Int, _ column: Int) -> Bool {
        for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
            let r = row + dr, c = column + dc
            guard r >= 0, r < grid.count, c >= 0, c < grid[r].count else { return true }
            if grid[r][c] == "." { return true }
        }
        return false
    }
}
