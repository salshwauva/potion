# Potion interface system

Recorded 2026-08-06. Values here are settled. Changing a derivation constant
means rechecking every skin, not just the one being looked at.

## Direction

A witchy apothecary terminal. The theme lives in surfaces, accents, and motif.
The terminal's own text area is a conventional high-legibility scheme, because
readability there is load-bearing and the theme does not get to compromise it.

Feel: candlelit, dense, quiet. The pixel art is an accent on a serious tool, not
the tool's voice.

## Skins

Six, selectable in Settings (Command-comma) or the Appearance menu, persisted in
`UserDefaults` under `appearance.skin`. Default is Alchemist.

| Skin | Hue | Surface sat | Accent | Mark | Motif |
|---|---|---|---|---|---|
| Cauldron | 268 | 0.34 | rose | rule | cauldron, sparkle, moon |
| Apothecary | 214 | 0.36 | brass | bracket | flask, key, candle |
| Moss & Moonlight | 148 | 0.30 | sage | moon phase | mushroom, moth, moon |
| Nocturne | 252 | 0.30 | lilac | star | sparkle, crystal, moon |
| Blush Grimoire | 348 | 0.28 | blush | ribbon | broom, candle, key |
| Alchemist | 322 | 0.26 | rose + brass | bracket | cauldron, flask, candle |

A skin supplies a hue, a saturation, three accent colors, a mark, and a motif.
Everything else is derived, so no skin can drift off the ladder or fall below AA.
Adding one means adding cases to `Skin`, not writing a palette.

Selection is never carried by color alone. Each skin also changes the *shape* of
the mark on the active tab, and every mark is drawn inside the tab's own bounds
so no skin can push the bar into the content below it.

## Derivation

**Surfaces** are five rungs on the skin's hue, lightness only:

```
0.075  terminalBackground   the well, darkest surface in the app
0.115  panelBackground      companion panel, canvas
0.155  windowChrome         wordmark bar, input bar
0.235  cardBackground       history and error cards, active tab
0.300  cardBackgroundRaised autocomplete popover
```

Saturation tapers 5% per rung so the lighter surfaces do not turn candied.
Adjacent rungs sit 4 to 8 lightness points apart. Below 4 the boundary stops
reading as structure; the pre-skin palette had `windowChrome` and
`panelBackground` 2 points apart and the two surfaces were indistinguishable.

WCAG ratios between adjacent dark surfaces are inherently near 1.1:1. Lightness
distance is the lever, not contrast ratio.

**Text** is four levels at saturation 0.24, lightness `0.94 / 0.80 / 0.68 / 0.56`.
Those numbers were solved against all six hues at once: the tightest pair
anywhere (tertiary on card) clears 4.85:1 and muted clears 3:1. The warm hues
are the binding constraint, not the plum the app started on.

`terminalForeground` is lightness 0.90, held under `textPrimary`. The well is
the darkest surface and pure white on it is tiring across a long session.

`rim` is the accent mixed 22% toward white. It is the glyph edge light and the
color of the small eyebrow labels.

## Typography

Three roles, and the split is enforced by the theme rather than by call sites.

**`chromeFont(size:)`** vends the pairing's pixel face. Exactly one caller: the
`POTION` wordmark. Sizes pass through `chromeOpticalScale`, which corrects for
cap height so the same argument renders at the same optical size in every
pairing:

| Pairing | Face | cap/em | scale |
|---|---|---|---|
| Glow | VT323 | 0.560 | 1.29 |
| Arcade | Press Start 2P | 1.000 | 0.72 |
| Clean | SF rounded | 0.72 | 1.00 |

Without the correction the two bundled pixel faces differ by 79% at the same
nominal size, so no single call-site value can serve both.

**`headingFont(size:)`** vends SF rounded semibold for section headings inside
the panels. Title case, no tracking.

**`labelFont(size:)`** vends SF rounded semibold for micro labels: tab titles,
section eyebrows, badges. Pair with `labelTracking` (0.9) when set in caps.

The rule underneath all three: **a pixel face never carries information.** It
lost the tab bar first (VT323 at 8pt drew 4.5pt caps), then the mascot caption,
which was a full sentence set in a bitmap face, then the section headings. The
identity is carried by the wordmark, the mascot sprite, and the motif glyphs,
which is plenty without also taxing the text that has to be read.

## Pixel art

`CatSprite` and `WitchyGlyph` share one idiom: 16 by 16 (the cat is 40 by 30)
character grids, one character per pixel, `.` empty, and **no authored outline**.
Any body pixel touching empty space is lit with `rim`. An authored dark outline
vanishes against surfaces this deep, which is exactly what happened on the first
attempt at the glyph set; the rim rule fixed all ten shapes at once and means a
silhouette can be edited without redrawing an outline.

The cat's fur is `terminalBackground`, so it stays a black cat but the skin's
black. A fixed plum-black read as a hole punched in the panel once the green and
brown skins existed.

Glyphs appear in the History and Errors empty states, drawn from
`skin.motif[0]` and `[1]`.

## Component patterns

**Tab** — 30pt height, `labelFont(11)` + tracking, 6pt radius, 2pt spacing.
Selection is `cardBackground` fill plus the skin's mark, both inside a shared
clip. Hover is the fill at 45%. Transitions `.easeOut(0.12)`. Carries
`.isSelected` for VoiceOver.

**Inline action** — `.buttonStyle(.potionLink)`, never `.buttonStyle(.link)`.
Rests at `accentSoft` 86%, hover 100%, pressed 55%, with `linkCursor()`.

**Selection in a list** — a tint plus a 2pt leading rule, never a text-color
change. Accent on `cardBackgroundRaised` is too low for AA as body text, so the
accent carries the rule and the text stays `textPrimary`.

**Skin tile** (Settings) — a miniature of the real window rather than a name in
a popup, because the choice is a visual one. Renders without the environment via
`PixelGlyphPreview`, so a tile can draw a skin that is not the active one.

## Rules that keep tripping this codebase

- Never `foregroundStyle(.secondary)` or `.tertiary`. The system semantic colors
  resolve against macOS's neutral gray dark scheme and land off-palette and
  under-contrasted. Bind to a palette token.
- Never hardcode an `NSColor` for the terminal. `PotionPalette` vends
  `terminalBackgroundNS`, `terminalForegroundNS`, `caretNS`, `selectionNS`.
- Never call `chromeFont` for anything but the wordmark.
- The terminal's native colors must not be touched before the shell is running,
  or SwiftTerm's initial draw breaks and the terminal renders blank. `start`
  applies them itself; `applyPalette` no-ops until `hasStarted`.

## Known gaps

- Every font is `fixedSize:`, which opts out of Dynamic Type (WCAG 1.4.4). macOS
  exposes no user text-size control that exercises this. Left as is.
- Dividers sit near 1.5:1. Decorative alongside the surface ladder, so exempt
  under 1.4.11.
- The Insert buttons in Docs and Errors still use `.buttonStyle(.bordered)` and
  render system chrome.
- The crystal glyph reads as a plain gem rather than a faceted one, and the
  candle's flame sits a pixel clear of its wick.
