import Foundation

/// Builds a list of ``CommandRecord`` values from the event stream produced by
/// ``ShellIntegrationScanner``. Pure logic with an injectable clock so the
/// timeline can be unit tested deterministically.
public final class CommandTimeline {
    public private(set) var records: [CommandRecord] = []
    public private(set) var isAlternateScreen = false

    private let now: () -> Date
    private var activeIndex: Int?
    private var pendingCwd: String?

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    /// Records the working directory reported by the shell. It is stamped onto
    /// the next command that begins.
    public func setCwd(_ path: String?) {
        pendingCwd = path
    }

    /// Applies one event and updates `records` in place.
    public func apply(_ event: TerminalEvent) {
        switch event {
        case .execStart:
            let record = CommandRecord(startedAt: now(), cwd: pendingCwd, status: .running)
            records.append(record)
            activeIndex = records.count - 1

        case .commandText(let text):
            if let index = activeIndex {
                records[index].command = text
            }

        case .commandFinished(let exitCode, let output):
            guard let index = activeIndex else { return }
            records[index].exitCode = exitCode
            records[index].finishedAt = now()
            records[index].capturedOutput = output
            records[index].status = (exitCode == 0) ? .success : .failure
            activeIndex = nil

        case .enterAlternateScreen:
            isAlternateScreen = true

        case .exitAlternateScreen:
            isAlternateScreen = false

        case .promptStart, .inputStart:
            break
        }
    }
}
