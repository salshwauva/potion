import SwiftUI

@main
struct PotionApp: App {
    @StateObject private var theme = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(theme)
                .frame(minWidth: 840, minHeight: 520)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Appearance") {
                Button("Cycle Skin") { theme.cycleSkin() }
                    .keyboardShortcut("k", modifiers: [.command, .option])
                Picker("Skin", selection: $theme.skin) {
                    ForEach(Skin.allCases) { skin in
                        Text(skin.displayName).tag(skin)
                    }
                }
                .pickerStyle(.inline)

                Divider()

                Button("Cycle Font Pairing") { theme.cycleFontPairing() }
                    .keyboardShortcut("f", modifiers: [.command, .option])
                Picker("Font Pairing", selection: $theme.pairing) {
                    ForEach(FontPairing.allCases) { pairing in
                        Text(pairing.displayName).tag(pairing)
                    }
                }
                .pickerStyle(.inline)
            }
        }

        Settings {
            AppearanceSettings()
                .environmentObject(theme)
        }
    }
}
