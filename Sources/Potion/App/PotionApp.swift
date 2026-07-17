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
    }
}
