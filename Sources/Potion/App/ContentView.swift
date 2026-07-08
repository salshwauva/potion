import SwiftUI

/// P0 shell: the raw terminal fills the window. Companion panel, subtitle bar,
/// and input bar arrive in later phases.
struct ContentView: View {
    var body: some View {
        TerminalPane()
            .ignoresSafeArea()
    }
}
