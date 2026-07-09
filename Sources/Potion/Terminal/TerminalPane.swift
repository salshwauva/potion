import SwiftUI
import SwiftTerm

/// Hosts the controller's terminal view and starts the shell. The view is a
/// genuine PTY backed zsh: TUI programs such as vim, htop, and less run
/// untouched. Command tracking happens alongside rendering, never in place of it.
struct TerminalPane: NSViewRepresentable {
    let controller: TerminalController

    func makeNSView(context: Context) -> PotionTerminalView {
        let view = controller.terminalView
        controller.start()
        return view
    }

    func updateNSView(_ nsView: PotionTerminalView, context: Context) {}
}
