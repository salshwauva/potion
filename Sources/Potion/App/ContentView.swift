import SwiftUI

/// P1 shell: the terminal on the left, a live command-tracking panel on the
/// right. The companion panel is a debug surface for now and is replaced by the
/// History, Docs, and Error sections in later phases.
struct ContentView: View {
    @StateObject private var controller = TerminalController()

    var body: some View {
        HSplitView {
            TerminalPane(controller: controller)
                .frame(minWidth: 420)
            DebugCommandList(controller: controller)
        }
    }
}
