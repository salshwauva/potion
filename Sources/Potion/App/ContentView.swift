import SwiftUI

/// P3 shell: the terminal with a docked input bar and a floating autocomplete
/// popup on the left, the History Panel on the right. The subtitle bar, docs,
/// and error sections arrive in later phases.
struct ContentView: View {
    @StateObject private var controller = TerminalController()

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
                    .padding(.bottom, 58)
                    .allowsHitTesting(controller.isCompletionVisible)
            }
            HistoryPanel(controller: controller)
        }
        .onAppear {
            DispatchQueue.main.async { controller.updateFocus() }
        }
    }
}
