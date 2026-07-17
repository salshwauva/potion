import SwiftUI

/// The full app: a pixel wordmark bar across the top, then the terminal with its
/// docked subtitle bar and input bar on the left and the companion panel on the
/// right. Everything is laid out with plain VStacks and explicit bar heights.
/// Two constraints drive this: applying `safeAreaInset` anywhere above the
/// SwiftTerm view breaks its drawing, and the wordmark and input bars collapse
/// to zero height without an explicit frame. The autocomplete popup floats as an
/// overlay (never a safe-area inset) so it does not disturb the terminal.
struct ContentView: View {
    @StateObject private var controller = TerminalController()
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            WindowChromeBar(controller: controller)
                .frame(height: 38)
            HSplitView {
                terminalColumn
                    .frame(minWidth: 420, minHeight: 260)
                CompanionPanel(controller: controller)
            }
        }
        .background(theme.palette.panelBackground)
        .onAppear {
            DispatchQueue.main.async { controller.updateFocus() }
        }
    }

    private var terminalColumn: some View {
        VStack(spacing: 0) {
            TerminalPane(controller: controller)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            InputBarView(controller: controller)
                .frame(height: 150)
        }
        .overlay(alignment: .bottomLeading) {
            AutocompletePopup(controller: controller)
                .padding(.horizontal, 12)
                .padding(.bottom, 158)
                .allowsHitTesting(controller.isCompletionVisible)
        }
    }
}
