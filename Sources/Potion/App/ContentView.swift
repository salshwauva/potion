import SwiftUI

/// The full app: terminal with a docked subtitle bar and input bar, a floating
/// autocomplete popup, and the companion panel with the mascot, History, Docs,
/// and Errors. The Potion theme lives in the chrome around the terminal; the
/// terminal's own text stays conventional and readable.
struct ContentView: View {
    @StateObject private var controller = TerminalController()
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        HSplitView {
            ZStack(alignment: .bottomLeading) {
                VStack(spacing: 0) {
                    TerminalPane(controller: controller)
                        .frame(minWidth: 420, minHeight: 240)
                    InputBarView(controller: controller)
                }
                AutocompletePopup(controller: controller)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 92)
                    .allowsHitTesting(controller.isCompletionVisible)
            }
            CompanionPanel(controller: controller)
        }
        .background(theme.palette.panelBackground)
        .onAppear {
            DispatchQueue.main.async { controller.updateFocus() }
        }
    }
}
