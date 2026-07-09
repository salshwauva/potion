import AppKit
import Combine
import Foundation
import PotionCore
import SwiftTerm

/// Where typed input is currently routed.
enum InputSink {
    /// Keystrokes compose a command in the input bar and run on Return.
    case inputBar
    /// Keystrokes go straight to the running program through the PTY.
    case terminal
}

/// Owns the terminal view and turns the raw PTY stream into a published command
/// timeline. It spawns a login and interactive zsh with the Potion shell
/// integration loaded through a ZDOTDIR shim, which leaves the user's own
/// startup files untouched. It also manages the input bar's focus passthrough.
@MainActor
final class TerminalController: NSObject, ObservableObject, LocalProcessTerminalViewDelegate {
    @Published private(set) var records: [CommandRecord] = []
    @Published private(set) var currentDirectory: String?
    @Published private(set) var isAlternateScreen = false
    @Published private(set) var isRunningCommand = false
    @Published private(set) var title: String = "Potion"

    /// Live text of the input bar, kept in sync with the field.
    @Published var draft: String = ""
    /// Manual override that forces keystrokes to the terminal (toggled by ⌘⇧T).
    @Published private(set) var manualPassthrough = false

    // Autocomplete state, published for the popup.
    @Published private(set) var completions: [Completion] = []
    @Published private(set) var selectedCompletion: Int = 0
    @Published private(set) var isCompletionVisible: Bool = false
    /// The remainder of the top suggestion beyond what is typed, for ghost text.
    @Published private(set) var ghostText: String = ""

    private let scanner = ShellIntegrationScanner()
    private let timeline = CommandTimeline()
    private var history = InputHistory()

    private let specEngine: SpecEngine?
    private let fileLister = FileManagerLister()
    private var completionDebounce: DispatchWorkItem?
    private var lastCompletion: CompletionResult?

    weak var inputField: NSTextField?

    override init() {
        specEngine = Self.loadSpecEngine()
        super.init()
    }

    private static func loadSpecEngine() -> SpecEngine? {
        guard let url = Bundle.main.url(forResource: "specs", withExtension: "json", subdirectory: "data")
            ?? Bundle.main.url(forResource: "specs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let specs = try? SpecStore.decode(data) else {
            // Graceful degradation: the terminal works without autocomplete.
            return nil
        }
        return SpecEngine(specs: specs)
    }

    private(set) lazy var terminalView: PotionTerminalView = {
        let view = PotionTerminalView(frame: .zero)
        view.processDelegate = self
        view.onRawData = { [weak self] slice in
            self?.ingest(slice)
        }
        return view
    }()

    /// Keystrokes go to the terminal while a full-screen program owns the screen,
    /// while a command is running (so prompts like sudo and read work), or when
    /// the manual override is on. Otherwise they compose a command in the bar.
    var inputSink: InputSink {
        (isAlternateScreen || isRunningCommand || manualPassthrough) ? .terminal : .inputBar
    }

    // MARK: Lifecycle

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
            case .execStart: isRunningCommand = true
            case .commandFinished: isRunningCommand = false
            case .enterAlternateScreen: isAlternateScreen = true
            case .exitAlternateScreen: isAlternateScreen = false
            default: break
            }
        }
        records = timeline.records
        updateFocus()
    }

    // MARK: Input bar

    /// Sends the current draft to the shell and clears the bar.
    func submitCurrentInput() {
        let line = draft
        terminalView.send(txt: line + "\n")
        draft = ""
        inputField?.stringValue = ""
        history.reset()
        clearCompletions()
    }

    /// Sends raw text straight to the terminal, bypassing the input bar. Used as
    /// a safety net when a program starts reading input mid-compose.
    func sendRaw(_ text: String) {
        terminalView.send(txt: text)
    }

    /// Inserts text into the input bar without executing it, and focuses the bar.
    func insertIntoInput(_ text: String) {
        manualPassthrough = false
        draft = text
        inputField?.stringValue = text
        clearCompletions()
        moveFocusToInput()
    }

    func historyPrevious() {
        history.setEntries(records.map(\.command))
        if let recalled = history.previous(currentDraft: draft) {
            draft = recalled
            inputField?.stringValue = recalled
            moveInsertionToEnd()
        }
    }

    func historyNext() {
        history.setEntries(records.map(\.command))
        if let recalled = history.next(currentDraft: draft) {
            draft = recalled
            inputField?.stringValue = recalled
            moveInsertionToEnd()
        }
    }

    // MARK: Autocomplete

    /// Recomputes suggestions for the current draft. Debounced and computed off
    /// the main thread so typing never blocks.
    func requestCompletions(text: String, cursor: Int) {
        completionDebounce?.cancel()

        guard let engine = specEngine, inputSink == .inputBar, !text.isEmpty else {
            clearCompletions()
            return
        }

        let cwd = currentDirectory ?? FileManager.default.currentDirectoryPath
        let lister = fileLister
        let work = DispatchWorkItem { [weak self] in
            let result = engine.complete(line: text, cursor: cursor, cwd: cwd, files: lister)
            DispatchQueue.main.async {
                guard let self, self.draft == text else { return }
                self.apply(result, forText: text, cursor: cursor)
            }
        }
        completionDebounce = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.03, execute: work)
    }

    private func apply(_ result: CompletionResult, forText text: String, cursor: Int) {
        lastCompletion = result
        completions = result.completions
        selectedCompletion = 0
        isCompletionVisible = !result.completions.isEmpty
        ghostText = computeGhost(result, text: text, cursor: cursor)
    }

    private func computeGhost(_ result: CompletionResult, text: String, cursor: Int) -> String {
        guard let top = result.completions.first, cursor == text.count else { return "" }
        let typedPrefix = String(Array(text)[result.replaceStart..<cursor])
        guard top.insertion.count > typedPrefix.count,
              top.insertion.hasPrefix(typedPrefix) else { return "" }
        return String(top.insertion.dropFirst(typedPrefix.count))
    }

    func clearCompletions() {
        completionDebounce?.cancel()
        completions = []
        isCompletionVisible = false
        ghostText = ""
        lastCompletion = nil
    }

    func moveCompletionUp() {
        guard isCompletionVisible, !completions.isEmpty else { return }
        selectedCompletion = (selectedCompletion - 1 + completions.count) % completions.count
    }

    func moveCompletionDown() {
        guard isCompletionVisible, !completions.isEmpty else { return }
        selectedCompletion = (selectedCompletion + 1) % completions.count
    }

    /// Applies the highlighted suggestion to the draft. Returns false when there
    /// is nothing to accept, so the caller can fall back to default behavior.
    @discardableResult
    func acceptCompletion() -> Bool {
        guard isCompletionVisible,
              let result = lastCompletion,
              completions.indices.contains(selectedCompletion) else {
            return false
        }
        let chosen = completions[selectedCompletion]
        var chars = Array(draft)
        let clampedEnd = min(result.replaceEnd, chars.count)
        chars.replaceSubrange(result.replaceStart..<clampedEnd, with: Array(chosen.insertion))
        let newText = String(chars)
        draft = newText
        inputField?.stringValue = newText
        let newCursor = result.replaceStart + chosen.insertion.count
        setInsertion(to: newCursor)
        clearCompletions()
        // A completed directory or subcommand can lead to further suggestions.
        requestCompletions(text: newText, cursor: newCursor)
        return true
    }

    func chooseCompletion(at index: Int) {
        guard completions.indices.contains(index) else { return }
        selectedCompletion = index
        acceptCompletion()
    }

    private func setInsertion(to location: Int) {
        guard let editor = inputField?.currentEditor() else { return }
        editor.selectedRange = NSRange(location: location, length: 0)
    }

    // MARK: Focus passthrough

    func toggleManualPassthrough() {
        manualPassthrough.toggle()
        updateFocus()
    }

    /// Moves keyboard focus to match the current input sink.
    func updateFocus() {
        guard let window = terminalView.window else { return }
        switch inputSink {
        case .terminal:
            if window.firstResponder !== terminalView {
                window.makeFirstResponder(terminalView)
            }
        case .inputBar:
            moveFocusToInput()
        }
    }

    private func moveFocusToInput() {
        guard let field = inputField, let window = field.window else { return }
        if window.firstResponder !== field.currentEditor() {
            window.makeFirstResponder(field)
        }
    }

    private func moveInsertionToEnd() {
        guard let editor = inputField?.currentEditor() else { return }
        editor.selectedRange = NSRange(location: (inputField?.stringValue as NSString?)?.length ?? 0, length: 0)
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
