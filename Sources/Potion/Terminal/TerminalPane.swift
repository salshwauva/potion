import SwiftUI
import SwiftTerm

/// Wraps SwiftTerm's macOS terminal view and spawns a login and interactive
/// zsh. This is a genuine PTY backed shell: TUI programs such as vim, htop,
/// and less run untouched. Later phases annotate around this view without
/// intercepting its rendering.
struct TerminalPane: NSViewRepresentable {
    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = LocalProcessTerminalView(frame: .zero)

        let shell = Self.loginShell()
        let shellName = (shell as NSString).lastPathComponent

        var env = Terminal.getEnvironmentVariables(termName: "xterm-256color", trueColor: true)
        if !env.contains(where: { $0.hasPrefix("LANG=") }) {
            env.append("LANG=en_US.UTF-8")
        }

        // A leading dash in argv[0] marks a login shell, which sources the
        // user's profile. Attachment to the PTY makes it interactive.
        view.startProcess(executable: shell, args: [], environment: env, execName: "-\(shellName)")

        return view
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {}

    /// zsh is the macOS default. SHELL is honored only when it already points
    /// at zsh; anything else falls back to the system zsh.
    private static func loginShell() -> String {
        if let shell = ProcessInfo.processInfo.environment["SHELL"], shell.hasSuffix("zsh") {
            return shell
        }
        return "/bin/zsh"
    }
}
