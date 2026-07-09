import SwiftUI

/// P2 shell: the terminal with a docked input bar on the left, the History Panel
/// on the right. The subtitle bar, docs, and error sections arrive in later
/// phases and slot into these same regions.
struct ContentView: View {
    @StateObject private var controller = TerminalController()

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                TerminalPane(controller: controller)
                    .frame(minWidth: 420, minHeight: 240)
                InputBarView(controller: controller)
            }
            HistoryPanel(controller: controller)
        }
        .onAppear {
            DispatchQueue.main.async { controller.updateFocus() }
        }
    }
}
