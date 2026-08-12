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

    /// The live translation of the current draft, or the frozen translation of
    /// the command that was just run.
    @Published private(set) var liveSubtitle: Subtitle = Subtitle(phrases: [])

    /// The command whose documentation should be shown, driven by the first word
    /// of the draft. Nil when the draft has no documented command.
    @Published private(set) var docsCommand: String?

    /// Explanations for commands that failed, newest first.
    @Published private(set) var errorCards: [IdentifiedErrorCard] = []
    /// The error card the user asked to see, used to scroll and switch tabs.
    @Published var focusedErrorId: UUID?

    /// Controls whether the right learning companion sidebar is visible.
    @Published var isSidebarVisible: Bool = true
    /// Controls whether the quick help & keyboard cheatsheet modal is open.
    @Published var showQuickHelpModal: Bool = false

    let tldrLibrary = TldrLibrary()
    private let errorEngine: ErrorRuleEngine?
    private lazy var knownCommands: [String] = Self.scanPath()

    private let scanner = ShellIntegrationScanner()
    private let timeline = CommandTimeline()
    /// Guards the terminal color work: the shell must be up before the native
    /// colors are touched, and re-applying an identical palette is wasted draw.
    private var hasStarted = false
    private var appliedPalette: PotionPalette?

    private var history = InputHistory()

    private let specEngine: SpecEngine?
    private let subtitleRenderer: SubtitleRenderer?
    private let fileLister = FileManagerLister()
    private var completionDebounce: DispatchWorkItem?
    private var subtitleDebounce: DispatchWorkItem?
    private var lastCompletion: CompletionResult?

    weak var inputField: NSTextField?

    override init() {
        let engine = Self.loadSpecEngine()
        specEngine = engine
        subtitleRenderer = engine.map { SubtitleRenderer(engine: $0, syntax: Self.loadSyntaxTable()) }
        errorEngine = Self.loadErrorEngine()
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

    private static func loadErrorEngine() -> ErrorRuleEngine? {
        guard let rulesURL = Bundle.main.url(forResource: "rules", withExtension: "json", subdirectory: "data")
            ?? Bundle.main.url(forResource: "rules", withExtension: "json"),
              let data = try? Data(contentsOf: rulesURL),
              let set = try? JSONDecoder().decode(ErrorRuleSet.self, from: data) else {
            return nil
        }
        var brew: [String] = []
        if let brewURL = Bundle.main.url(forResource: "brew-formulae", withExtension: "txt", subdirectory: "data")
            ?? Bundle.main.url(forResource: "brew-formulae", withExtension: "txt"),
           let text = try? String(contentsOf: brewURL, encoding: .utf8) {
            brew = text.split(whereSeparator: \.isNewline).map(String.init)
        }
        return ErrorRuleEngine(rules: set.rules, brewFormulae: brew)
    }

    /// Executable names found on PATH, used for typo suggestions.
    private static func scanPath() -> [String] {
        let path = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let fm = FileManager.default
        var names = Set<String>()
        for directory in path.split(separator: ":").map(String.init) {
            guard let entries = try? fm.contentsOfDirectory(atPath: directory) else { continue }
            names.formUnion(entries)
        }
        return Array(names)
    }

    private static func loadSyntaxTable() -> SyntaxTable {
        guard let url = Bundle.main.url(forResource: "syntax", withExtension: "json", subdirectory: "data")
            ?? Bundle.main.url(forResource: "syntax", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode(SyntaxTable.self, from: data) else {
            return .builtin
        }
        return table
    }

    /// The bundled commands, for the browsable common-commands list. Empty when
    /// the spec data failed to load.
    var commonCommands: [CommandSpec] {
        specEngine?.allSpecs ?? []
    }

    /// Renders a subtitle synchronously. Cheap enough for per-row use in the
    /// History Panel. Returns an empty subtitle when the engine is unavailable.
    func subtitle(for command: String) -> Subtitle {
        subtitleRenderer?.render(command) ?? Subtitle(phrases: [])
    }

    /// Updates which command's documentation to surface, based on the first word
    /// of the current draft.
    func updateDocs(text: String) {
        let tokens = Tokenizer.tokenize(text)
        guard let first = tokens.first(where: { $0.kind == .word }), tldrLibrary.hasPage(named: first.value) else {
            docsCommand = nil
            return
        }
        docsCommand = first.value
    }

    /// The mascot mirrors the command lifecycle. Success and failure are held
    /// briefly, then settle back to idle or typing.
    @Published private(set) var mascotState: MascotState = .idle
    private var mascotSettleWork: DispatchWorkItem?

    private(set) lazy var terminalView: PotionTerminalView = {
        // A sane initial size matters: the shell is spawned before SwiftUI has
        // laid the view out, so a zero frame would create the PTY at 0x0 and the
        // first prompt would be printed into nothing. A real size gives the PTY
        // sensible rows and columns; it reflows when SwiftUI resizes the view.
        let view = PotionTerminalView(frame: CGRect(x: 0, y: 0, width: 800, height: 480))
        view.processDelegate = self
        view.onRawData = { [weak self] slice in
            self?.ingest(slice)
        }
        return view
    }()

    /// The terminal's own text uses a conventional, high-legibility scheme on a
    /// dark plum background. The witchy colors stay in the chrome, never here.
    private static func apply(_ palette: PotionPalette, to view: PotionTerminalView) {
        view.nativeBackgroundColor = palette.terminalBackgroundNS
        view.nativeForegroundColor = palette.terminalForegroundNS
        view.caretColor = palette.caretNS
        view.selectedTextBackgroundColor = palette.selectionNS
    }

    /// Re-colors a running terminal when the skin changes. Does nothing before
    /// the shell is up: setting the native colors on an unattached view leaves
    /// the terminal blank, which is why `start` applies them itself.
    func applyPalette(_ palette: PotionPalette) {
        guard hasStarted, palette != appliedPalette else { return }
        appliedPalette = palette
        Self.apply(palette, to: terminalView)
    }

    /// Keystrokes go to the terminal while a full-screen program owns the screen,
    /// while a command is running (so prompts like sudo and read work), or when
    /// the manual override is on. Otherwise they compose a command in the bar.
    var inputSink: InputSink {
        (isAlternateScreen || isRunningCommand || manualPassthrough) ? .terminal : .inputBar
    }

    // MARK: Lifecycle

    /// Spawns the shell. Safe to call once after the view is attached.
    func start(palette: PotionPalette) {
        guard !hasStarted else { return }

        let shell = Self.loginShell()
        let shellName = (shell as NSString).lastPathComponent
        let environment = Self.buildEnvironment()

        terminalView.startProcess(
            executable: shell,
            args: [],
            environment: environment,
            execName: "-\(shellName)"
        )

        hasStarted = true

        // Apply the terminal palette only after the process is running. Setting
        // the native colors on a freshly constructed, unattached view breaks
        // SwiftTerm's initial draw, leaving the terminal blank.
        appliedPalette = palette
        Self.apply(palette, to: terminalView)
    }

    private func ingest(_ slice: ArraySlice<UInt8>) {
        let events = scanner.feed(slice)
        guard !events.isEmpty else { return }
        for event in events {
            timeline.apply(event)
            switch event {
            case .execStart:
                isRunningCommand = true
                mascotSettleWork?.cancel()
                mascotState = .running
            case .commandFinished(let exitCode, let output):
                isRunningCommand = false
                mascotState = (exitCode == 0) ? .success : .failure
                scheduleMascotSettle()
                if let exitCode, exitCode != 0, let record = timeline.records.last {
                    explainFailure(record: record, exitCode: exitCode, output: output)
                }
            case .enterAlternateScreen: isAlternateScreen = true
            case .exitAlternateScreen: isAlternateScreen = false
            default: break
            }
        }
        records = timeline.records
        updateFocus()
        refreshMascot()
    }

    private func explainFailure(record: CommandRecord, exitCode: Int32, output: String) {
        guard let engine = errorEngine, !record.command.isEmpty else { return }
        guard let card = engine.explain(command: record.command, exitCode: exitCode, output: output, knownCommands: knownCommands) else { return }
        errorCards.insert(IdentifiedErrorCard(id: record.id, command: record.command, card: card), at: 0)
        focusedErrorId = record.id
    }

    /// Brings the error card for a record into view.
    func focusError(_ id: UUID) {
        focusedErrorId = id
    }

    // MARK: Mascot

    /// Refreshes the mascot for the current typing and running state, unless an
    /// outcome beat is being held.
    func refreshMascot() {
        guard mascotState != .success, mascotState != .failure else { return }
        mascotState = MascotState.classify(
            isRunning: isRunningCommand,
            isAlternateScreen: isAlternateScreen,
            draftEmpty: draft.isEmpty
        )
    }

    private func scheduleMascotSettle() {
        mascotSettleWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.mascotState == .success || self.mascotState == .failure else { return }
            self.mascotState = self.draft.isEmpty ? .idle : .typing
        }
        mascotSettleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: work)
    }

    func hasErrorCard(for id: UUID) -> Bool {
        errorCards.contains { $0.id == id }
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
        // Freeze the translation of the command that was just run until the next
        // keystroke replaces it.
        subtitleDebounce?.cancel()
        liveSubtitle = subtitle(for: line)
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

    // MARK: Live subtitle

    /// Recomputes the live subtitle for the draft. Debounced and off the main
    /// thread so the translation never blocks typing.
    func requestSubtitle(text: String) {
        subtitleDebounce?.cancel()

        guard let renderer = subtitleRenderer, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            liveSubtitle = Subtitle(phrases: [])
            return
        }

        let work = DispatchWorkItem { [weak self] in
            let subtitle = renderer.render(text)
            DispatchQueue.main.async {
                guard let self, self.draft == text else { return }
                self.liveSubtitle = subtitle
            }
        }
        subtitleDebounce = work
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.08, execute: work)
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

    // MARK: Sidebar & Learning Helpers

    func toggleSidebar() {
        isSidebarVisible.toggle()
    }

    func toggleQuickHelp() {
        showQuickHelpModal.toggle()
    }

    func tokenBreakdown(for line: String) -> [IdentifiedTokenBreakdown] {
        let tokens = Tokenizer.tokenize(line)
        guard !tokens.isEmpty else { return [] }
        let sub = subtitle(for: line)
        let segments = Tokenizer.segments(tokens)

        var tokenDomainMap: [Int: CommandDomain] = [:]
        for segment in segments {
            for (pos, token) in segment.tokens.enumerated() {
                if let idx = tokens.firstIndex(where: { $0.start == token.start && $0.raw == token.raw }) {
                    tokenDomainMap[idx] = CommandDomain.classify(token: token, positionInSegment: pos)
                }
            }
        }

        var result: [IdentifiedTokenBreakdown] = []
        for (index, token) in tokens.enumerated() {
            let domain = tokenDomainMap[index] ?? .generic
            var cat = domain.displayName
            if token.value.hasPrefix("$") { cat = "Variable" }

            let matchingPhrase = sub.phrases.first { phrase in
                if let start = phrase.sourceStart, let end = phrase.sourceEnd {
                    return token.start >= start && token.end <= end
                }
                return false
            }

            let exp = matchingPhrase?.text ?? (token.kind == .word ? "Run program \(token.value)" : "Value \(token.raw)")
            let conf = matchingPhrase?.confidence ?? .known

            result.append(IdentifiedTokenBreakdown(
                token: token,
                category: cat,
                domain: domain,
                explanation: exp,
                confidence: conf
            ))
        }

        return result
    }

    func contextualSuggestions() -> [CommandSuggestion] {
        var items: [CommandSuggestion] = []
        let cwd = currentDirectory ?? FileManager.default.currentDirectoryPath

        let fm = FileManager.default
        let hasGit = fm.fileExists(atPath: (cwd as NSString).appendingPathComponent(".git"))
        let hasSwift = fm.fileExists(atPath: (cwd as NSString).appendingPathComponent("Package.swift")) ||
                         fm.fileExists(atPath: (cwd as NSString).appendingPathComponent("project.yml"))
        let hasNode = fm.fileExists(atPath: (cwd as NSString).appendingPathComponent("package.json"))

        if hasGit {
            items.append(CommandSuggestion(
                command: "git status",
                title: "Check Git Status",
                description: "View working tree changes and staged files",
                category: "Git Workflow",
                badge: "GIT"
            ))
            items.append(CommandSuggestion(
                command: "git log --oneline -n 5",
                title: "View Recent Commits",
                description: "Compact timeline of recent repository commits",
                category: "Git Workflow",
                badge: "GIT"
            ))
        }

        if hasSwift {
            items.append(CommandSuggestion(
                command: "swift test",
                title: "Run Swift Unit Tests",
                description: "Execute all unit test suites in project",
                category: "Build & Test",
                badge: "SWIFT"
            ))
        }

        if hasNode {
            items.append(CommandSuggestion(
                command: "npm test",
                title: "Run NPM Tests",
                description: "Execute test scripts defined in package.json",
                category: "Node.js",
                badge: "NPM"
            ))
        }

        items.append(CommandSuggestion(
            command: "ls -la",
            title: "List Detailed Files",
            description: "Show all files including hidden ones with sizes",
            category: "Directory Inspection",
            badge: "FILES"
        ))

        items.append(CommandSuggestion(
            command: "pwd",
            title: "Print Working Directory",
            description: "Display absolute path of current folder",
            category: "Navigation",
            badge: "NAV"
        ))

        if let lastRecord = records.last {
            let cmd = lastRecord.command.trimmingCharacters(in: .whitespaces)
            if cmd.hasPrefix("mkdir ") {
                let folder = String(cmd.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                items.insert(CommandSuggestion(
                    command: "cd \(folder)",
                    title: "Enter New Folder",
                    description: "Navigate into directory created by previous command",
                    category: "Suggested Next Step",
                    badge: "NEXT"
                ), at: 0)
            } else if cmd.hasPrefix("git add") {
                items.insert(CommandSuggestion(
                    command: "git commit -m \"Update\"",
                    title: "Commit Staged Changes",
                    description: "Save staged changes into git repository history",
                    category: "Suggested Next Step",
                    badge: "NEXT"
                ), at: 0)
            }
        }

        return items
    }
}

public struct IdentifiedTokenBreakdown: Identifiable, Equatable {
    public let id = UUID()
    public let token: Token
    public let category: String
    let domain: CommandDomain
    public let explanation: String
    public let confidence: SubtitlePhrase.Confidence

    public static func == (lhs: IdentifiedTokenBreakdown, rhs: IdentifiedTokenBreakdown) -> Bool {
        lhs.id == rhs.id
    }
}

public struct CommandSuggestion: Identifiable, Equatable {
    public let id = UUID()
    public let command: String
    public let title: String
    public let description: String
    public let category: String
    public let badge: String?

    public static func == (lhs: CommandSuggestion, rhs: CommandSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}

