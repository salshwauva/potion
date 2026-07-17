import SwiftUI

/// The full app: terminal with a docked subtitle bar and input bar, a floating
/// autocomplete popup, and the companion panel with the mascot, History, Docs,
/// and Errors. The wordmark bar and input composer attach as safe-area insets so
/// a greedy terminal can never squeeze them out. `fixedSize(vertical:)` gives
/// each inset its true content height (the composer grows with a wrapping
/// subtitle) instead of collapsing to zero.
struct ContentView: View {
    @StateObject private var controller = TerminalController()
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        HSplitView {
            ZStack(alignment: .bottomLeading) {
                TerminalPane(controller: controller)
                    .frame(minWidth: 420, minHeight: 200)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        InputBarView(controller: controller)
                            .frame(height: 150)
                    }
                AutocompletePopup(controller: controller)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 96)
                    .allowsHitTesting(controller.isCompletionVisible)
            }
            CompanionPanel(controller: controller)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            WindowChromeBar(controller: controller)
                .frame(height: 38)
        }
        .background(theme.palette.panelBackground)
        .onAppear {
            DispatchQueue.main.async { controller.updateFocus() }
        }
    }
}
