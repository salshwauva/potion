# Attributions

Potion bundles third party software and data. Each component is listed with its
license. This file is maintained from the first phase and updated as components
are added.

## In use now

### SwiftTerm

Terminal emulator and PTY handling.

- Source: https://github.com/migueldeicaza/SwiftTerm
- License: MIT

## Planned (added in later phases)

### tldr pages

Command documentation shown in the docs panel. The bundled English `common` and
`osx` pages are the tldr-pages project's own content, included offline.

- Source: https://github.com/tldr-pages/tldr
- License: CC-BY 4.0
- Attribution: tldr pages content is distributed under Creative Commons
  Attribution. The tldr-pages project and its contributors are credited here and
  in the app's About and Docs sections.

## Planned (added in later phases)

### Fig autocomplete specs

The command specification format mirrors Fig's autocomplete specs. The bundled
specs are authored natively (see docs/decisions.md, ADR-0005); a Fig-to-JSON
importer can widen coverage later.

- Source: https://github.com/withfig/autocomplete
- License: MIT

## Also in use

### Fonts

Bundled typefaces for the theme system. All are openly licensed. The pixel faces
are used only for chrome, headings, and badges, never for terminal text or
subtitles.

- Press Start 2P: SIL Open Font License 1.1 (bundled)
- VT323: SIL Open Font License 1.1 (bundled)
- JetBrains Mono: SIL Open Font License 1.1 (bundled)
- SF Mono: system font, not bundled
- Berkeley Mono: commercial license, excluded unless separately licensed
