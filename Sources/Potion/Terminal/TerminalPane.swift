import SwiftUI
import SwiftTerm

/// Hosts the controller's terminal view and starts the shell. The view is a
/// genuine PTY backed zsh: TUI programs such as vim, htop, and less run
/// untouched. Command tracking happens alongside rendering, never in place of it.
///
/// The palette arrives from here rather than being read inside the controller,
/// so the shell starts with the active skin already resolved and a later skin
/// change re-colors the running terminal through `updateNSView`.
struct TerminalPane: NSViewRepresentable {
    let controller: TerminalController
    let palette: PotionPalette

    func makeNSView(context: Context) -> PotionTerminalView {
        let view = controller.terminalView
        controller.start(palette: palette)
        return view
    }

    func updateNSView(_ nsView: PotionTerminalView, context: Context) {
        controller.applyPalette(palette)
    }
}
