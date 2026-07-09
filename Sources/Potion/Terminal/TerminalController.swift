import AppKit
import Combine
import Foundation
import PotionCore
import SwiftTerm

/// Owns the terminal view and turns the raw PTY stream into a published command
/// timeline. It spawns a login and interactive zsh with the Potion shell
/// integration loaded through a ZDOTDIR shim, which leaves the user's own
/// startup files untouched.
@MainActor
final class TerminalController: NSObject, ObservableObject, LocalProcessTerminalViewDelegate {
    @Published private(set) var records: [CommandRecord] = []
    @Published private(set) var currentDirectory: String?
    @Published private(set) var isAlternateScreen = false
    @Published private(set) var title: String = "Potion"

    private let scanner = ShellIntegrationScanner()
    private let timeline = CommandTimeline()

    private(set) lazy var terminalView: PotionTerminalView = {
        let view = PotionTerminalView(frame: .zero)
        view.processDelegate = self
        view.onRawData = { [weak self] slice in
            self?.ingest(slice)
        }
        return view
    }()

    /// Spawns the shell. Safe to call once after the view is attached.
    func start() {
        guard terminalView.process == nil || terminalView.process.running == false else { return }

        let shell = Self.loginShell()
        let shellName = (shell as NSString).lastPathComponent
        let environment = Self.buildEnvironment()

        terminalView.startProcess(
            executable: shell,
            args: [],
            environment: environment,
            execName: "-\(shellName)"
        )
    }

    private func ingest(_ slice: ArraySlice<UInt8>) {
        let events = scanner.feed(slice)
        guard !events.isEmpty else { return }
        for event in events {
            timeline.apply(event)
            switch event {
            case .enterAlternateScreen: isAlternateScreen = true
            case .exitAlternateScreen: isAlternateScreen = false
            default: break
            }
        }
        records = timeline.records
    }

    // MARK: LocalProcessTerminalViewDelegate

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        self.title = title.isEmpty ? "Potion" : title
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        currentDirectory = directory
        timeline.setCwd(directory)
    }

    func processTerminated(source: TerminalView, exitCode: Int32?) {}

    // MARK: Shell configuration

    /// zsh is the macOS default. SHELL is honored only when it already points at
    /// zsh; anything else falls back to the system zsh.
    private static func loginShell() -> String {
        if let shell = ProcessInfo.processInfo.environment["SHELL"], shell.hasSuffix("zsh") {
            return shell
        }
        return "/bin/zsh"
    }

    /// Builds the child environment, pointing ZDOTDIR at the bundled shim so the
    /// shell integration loads. The user's original ZDOTDIR (or home) is passed
    /// through so the shim can source their real startup files.
    private static func buildEnvironment() -> [String] {
        var env = Terminal.getEnvironmentVariables(termName: "xterm-256color", trueColor: true)
        if !env.contains(where: { $0.hasPrefix("LANG=") }) {
            env.append("LANG=en_US.UTF-8")
        }

        // Drop any inherited keys the shim manages, then set them explicitly.
        env.removeAll { line in
            line.hasPrefix("ZDOTDIR=") || line.hasPrefix("POTION=") || line.hasPrefix("POTION_USER_ZDOTDIR=")
        }
        env.append("POTION=1")

        if let shimDir = Bundle.main.url(forResource: "zsh", withExtension: nil)?.path {
            let userZDotDir = ProcessInfo.processInfo.environment["ZDOTDIR"] ?? NSHomeDirectory()
            env.append("POTION_USER_ZDOTDIR=\(userZDotDir)")
            env.append("ZDOTDIR=\(shimDir)")
        }

        return env
    }
}
