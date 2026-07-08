# Potion

A subtitled terminal for macOS. Potion runs a real zsh shell and renders live
plain English translations of every command, as it is typed and attached to
every command in history. The goal is fluency through immersion plus
translation, not through forms or tutorials.

Potion is a genuine terminal. Friendly features (subtitles, autocomplete, docs,
error explanations) surround and annotate the shell. They never replace or hide
it.

## Status

Phase P0: scaffold and raw terminal. The app spawns a login and interactive
zsh in a SwiftTerm backed PTY. TUI programs such as vim and htop run untouched.
Later phases add command tracking, an input bar, autocomplete, subtitles, docs,
error cards, and the Potion theme.

## Requirements

- macOS 14 or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build

The Xcode project is generated from `project.yml` and is not checked in.

```sh
# Point the toolchain at the full Xcode (only needed if xcode-select
# currently points at the Command Line Tools).
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Generate Potion.xcodeproj from project.yml.
xcodegen generate

# Build.
xcodebuild -project Potion.xcodeproj -scheme Potion -configuration Debug build

# Run the tests.
xcodebuild -project Potion.xcodeproj -scheme Potion test
```

Open `Potion.xcodeproj` in Xcode to run the app with the Run button.

## Architecture

Logic and UI are split into two targets so the translation engine is unit
testable without AppKit or a running app.

- `PotionCore`: pure logic. Tokenizer, spec walker, subtitle renderer, syntax
  table, rule engine, and terminal parsers. No AppKit.
- `Potion`: the SwiftUI app. Terminal wrapper, input bar, companion panels,
  theme, mascot. Depends on `PotionCore`.

The command line is parsed once by a single engine that feeds two consumers:
autocomplete suggestions and subtitle translations.

## License and attributions

See [ATTRIBUTIONS.md](ATTRIBUTIONS.md).
