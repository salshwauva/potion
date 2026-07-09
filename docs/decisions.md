# Decisions

Short records of design choices where the chosen approach is not the obvious or
proportionate one, or where the reasoning is worth keeping. Newest last.

## ADR-0001: Xcode project generated from project.yml via XcodeGen

The `.xcodeproj` is generated, not checked in. `project.yml` is the source of
truth. This keeps the project definition readable and diff friendly and avoids
hand editing `pbxproj`. Cost: contributors need XcodeGen installed and must run
`xcodegen generate` before the first build.

## ADR-0002: Logic and UI split into PotionCore and Potion

All translation and parsing logic lives in `PotionCore`, a framework target
with no AppKit dependency. The app target depends on it. This exists because the
engineering ground rules require heavy unit testing of the tokenizer, spec
walker, subtitle renderer (40 plus golden cases), and parsers, plus off main
parsing for performance. Logic embedded in SwiftUI views would be neither.

## ADR-0003: Build via DEVELOPER_DIR rather than global xcode-select

The development machine had `xcode-select` pointing at the Command Line Tools.
Builds run with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` set
for the invocation, which avoids a global sudo change. The README documents the
one time `xcode-select -s` command for normal Xcode use.

## ADR-0005: Native SpecEngine over bundled JSON, not Fig specs in JavaScriptCore

The spec calls for Fig's TypeScript autocomplete specs compiled to JS and run in
JavaScriptCore. That path requires reproducing the Fig runtime (loadSpec,
generators, thousands of interdependent TS modules) inside JSCore, a large and
fragile subsystem. The implemented approach is a native tokenizer and spec-tree
walker (`SpecEngine`) over a Codable `CommandSpec` model, populated from bundled
JSON (`Resources/data/specs.json`).

Consequences:
  - The engine is pure Swift and unit tested, which the ground rules require, and
    it is the single parser feeding both autocomplete and the subtitle renderer.
  - No JavaScriptCore dependency and a tiny bundle.
  - The spec set is hand-authored and smaller than the full Fig catalog. The
    `CommandSpec` shape mirrors Fig's, so a build-time importer that converts Fig
    specs to this JSON can widen coverage later without touching the engine.
  - Dynamic generators remain deferred, as the spec intended. The
    `SpecEngine.complete` argument path is where a generator hook attaches.

This is a deviation from the written spec and is flagged for review.

## ADR-0006: Theme applied via tokens; contrast verified; pixel window frame deferred

Colors and fonts are tokens on `ThemeManager` / `PotionPalette`, injected as an
environment object so views never hardcode a palette value. Status, accent, and
surface colors all resolve through the palette. The terminal body keeps a
separate, conventional scheme (light text on dark plum) set on the SwiftTerm view.

Contrast was measured, not assumed. Terminal text reads at 13.8:1 on the plum
background; subtitles read at 14.5:1 (known) and 8.0:1 (honestly-unknown). Both
clear WCAG AA for normal text. The tertiary tone (separators and the empty-state
hint) sits at 4.3:1, which clears AA for large text only, and is used only for
non-essential decoration.

Deferred: the fully custom pixel-art NSWindow titlebar and chunky frame from the
mockups. The witchy identity is carried by the plum surfaces, pink rim accents,
pixel display fonts, and the reactive mascot. A custom window frame is a larger
AppKit undertaking and is not required for the theme to read as Potion.

## ADR-0004: Ad hoc code signing for local development

The app target signs ad hoc (`CODE_SIGN_IDENTITY = "-"`, manual style, no
team). App Sandbox is off, which is required to spawn a shell process. This is a
local development configuration only and is not suitable for distribution.
