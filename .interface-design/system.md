# Potion interface system

Recorded 2026-08-06, from the legibility and palette pass on the companion panel
and chrome. Values here are settled. Changing one means rechecking the contrast
table at the bottom.

## Direction

A witchy apothecary terminal. The plum and pink identity lives in the chrome,
panels, and accents. The terminal's own text area is a conventional
high-legibility scheme, because readability there is load-bearing and the theme
does not get to compromise it.

Feel: candlelit, dense, quiet. Not neon, not playful. The pixel faces are an
accent on a serious tool, not the tool's voice.

## Depth strategy

Surface ladder only. No shadows, no decorative borders. Depth comes from five
rungs on a single hue (268), varying lightness and nothing else.

| Token | sRGB | HSL L | Role |
|---|---|---|---|
| `terminalBackground` | 0.073, 0.045, 0.105 | 7.5 | the well, darkest surface in the app |
| `panelBackground` | 0.112, 0.074, 0.156 | 11.5 | companion panel, canvas |
| `windowChrome` | 0.151, 0.102, 0.208 | 15.5 | wordmark bar, input bar |
| `cardBackground` | 0.230, 0.167, 0.303 | 23.5 | history and error cards, active tab |
| `cardBackgroundRaised` | 0.295, 0.219, 0.381 | 30.0 | autocomplete popover |

Adjacent rungs sit 4 to 8 lightness points apart. Below 4 points the boundary
stops reading as structure; the pre-pass palette had `windowChrome` and
`panelBackground` 2 points apart and the two surfaces were indistinguishable.

WCAG ratios between adjacent dark surfaces are inherently near 1.1:1. Lightness
distance is the lever, not contrast ratio.

## Text scale

Four levels. Each clears AA on every surface it appears on.

| Token | sRGB | Use |
|---|---|---|
| `textPrimary` | 0.94, 0.92, 0.99 | command text, headings, card body |
| `textSecondary` | 0.78, 0.72, 0.89 | metadata, descriptions, inactive tabs, empty states |
| `textTertiary` | 0.66, 0.60, 0.78 | separators, hints, overflow counts |
| `textMuted` | 0.50, 0.45, 0.61 | disabled controls only, exempt under 1.4.3 |

`terminalForeground` (0.91, 0.88, 0.96) sits under `textPrimary` on purpose. The
well is the darkest surface and pure white on it is tiring across a long session.

## Typography

Two roles, and the distinction is enforced by the theme rather than by call sites.

**`chromeFont(size:)`** vends the pairing's pixel face for the wordmark and
section headings. Intended for 12pt and up. Sizes pass through
`chromeOpticalScale`, which corrects for cap height so the same argument renders
at the same optical size in every pairing:

| Pairing | Face | cap/em | scale |
|---|---|---|---|
| Glow | VT323 | 0.560 | 1.29 |
| Arcade | Press Start 2P | 1.000 | 0.72 |
| Clean | SF rounded | 0.72 | 1.00 |

Without the correction the two bundled pixel faces differ by 79% at the same
nominal size, so no single call-site value can serve both.

**`labelFont(size:)`** vends SF rounded semibold for micro labels: tab titles,
section eyebrows, badges. Never a pixel face. Small caps in a bitmap face lose
their counters at any size the chrome can afford, which is what made the
`HISTORY / DOCS / ERRORS` bar unreadable at VT323 8pt (caps 4.5pt tall). Pair
with `labelTracking` (0.9) whenever the text is set in caps.

## Component patterns

**Tab (`PixelTabBar`)** — 30pt height, `labelFont(11)` + tracking, 6pt radius,
2pt spacing between tabs. Selection reads twice: `cardBackground` fill plus a 2pt
`accent` rule at the bottom, both inside a shared clip so the rule tucks into the
corners. Hover is the fill at 45%. Transitions are `.easeOut(0.12)`. Carries
`.isSelected` for VoiceOver.

**Inline action** — `PotionLinkButtonStyle` (`.buttonStyle(.potionLink)`), never
`.buttonStyle(.link)`. The system style paints macOS accent blue, the one cold
color in a warm interface. Rests at `accentSoft` 86%, hover 100%, pressed 55%,
with `linkCursor()`.

**Selection in a list** — a tint plus a 2pt leading rule, never a text-color
change. Accent pink on `cardBackgroundRaised` reaches only 3.8:1, short of AA for
body text, so the accent carries the rule and the text stays `textPrimary`.

## Rules that keep tripping this codebase

- Never `foregroundStyle(.secondary)` or `.tertiary`. The system semantic colors
  resolve against macOS's neutral gray dark scheme and land off-palette and
  under-contrasted on plum. Bind to a palette token.
- Never hardcode an `NSColor` for the terminal. `PotionPalette` vends
  `terminalBackgroundNS`, `terminalForegroundNS`, `caretNS`, `selectionNS`.
- Never call `chromeFont` below 12. Use `labelFont`.

## Known gaps

- Every font is `fixedSize:`, which opts out of Dynamic Type (WCAG 1.4.4). macOS
  exposes no user text-size control that exercises this. Left as is.
- Dividers sit near 1.5:1. Decorative alongside the surface ladder, so exempt
  under 1.4.11. Reaching 3:1 on these surfaces needs roughly 38% white, which
  reads as scaffolding.
- The Insert buttons in Docs and Errors still use `.buttonStyle(.bordered)` and
  render system chrome.

## Contrast table

Verified against the ladder above. Body text needs 4.5:1, UI components 3:1.

| Element | Ratio |
|---|---|
| Inactive tab label on panel | 9.68 |
| Active tab label on card | 11.00 |
| Card body text | 6.96 |
| Card tertiary text | 4.94 |
| Kbd chip glyph on chrome | 8.85 |
| Autocomplete selected row | 8.81 |
| Active tab accent rule | 6.65 |
| Terminal body in the well | 15.07 |
