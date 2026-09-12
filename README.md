# Potion

Potion is a macOS terminal with plain-English command subtitles. It runs a zsh shell and explains supported commands as they enter the input bar.

The same command parser supplies subtitles and autocomplete. A history panel keeps command records, while nearby panels show command documentation and explanations for recognized errors.

## Features

- A SwiftTerm terminal with an interactive login shell and support for terminal applications.
- Command subtitles based on local specifications and syntax rules.
- Autocomplete for supported commands, flags, and paths.
- Offline command examples from bundled tldr pages.
- Rule-based error cards and a themed interface with a reactive mascot.

The explanations run locally. The app does not require a model service or an API key.

## Requirements

- macOS 14 or later.
- Xcode 16 or later, selected as the active developer toolchain.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Build and run

The repository uses `project.yml` to generate the Xcode project:

```sh
xcodegen generate
open Potion.xcodeproj
```

Select the `Potion` scheme in Xcode and run the app. A command-line build uses the same scheme:

```sh
xcodebuild -project Potion.xcodeproj -scheme Potion -configuration Debug build
```

If the active toolchain points to the Command Line Tools, select the full Xcode installation:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Tests

```sh
xcodebuild -project Potion.xcodeproj -scheme Potion test
```

The tests cover tokenization, command specifications, subtitles, error rules, documentation, and terminal events.

## Architecture

`PotionCore` contains the parser, command specifications, subtitle rules, error rules, and terminal event models. It does not depend on AppKit.

`Potion` contains the SwiftUI app and SwiftTerm integration. It connects the shell to the input bar, history, and companion panels.

| Path | Purpose |
| --- | --- |
| `Sources/PotionCore/` | Command logic and terminal event models |
| `Sources/Potion/` | App interface and terminal integration |
| `Resources/data/` | Command specifications and explanation rules |
| `Resources/tldr/` | Offline command documentation |
| `Tests/PotionCoreTests/` | Unit tests |

[Design decisions](docs/decisions.md) describes the module split and shell integration.

## Status and limits

The repository contains the terminal, subtitles, autocomplete, documentation, error cards, and theme. It builds from source.

Subtitle coverage depends on the bundled command specifications. Error cards only cover recognized patterns. The shell can run commands outside that coverage.

Potion executes shell commands with the current user's permissions. A subtitle does not establish that a command is safe.

## Third-party credits

[ATTRIBUTIONS.md](ATTRIBUTIONS.md) lists SwiftTerm, tldr pages, and the bundled fonts with their licenses.
