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

## ADR-0004: Ad hoc code signing for local development

The app target signs ad hoc (`CODE_SIGN_IDENTITY = "-"`, manual style, no
team). App Sandbox is off, which is required to spawn a shell process. This is a
local development configuration only and is not suitable for distribution.
