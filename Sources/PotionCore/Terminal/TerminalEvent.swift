import Foundation

/// Semantic events extracted from the PTY byte stream by
/// ``ShellIntegrationScanner``. These describe the shell's command lifecycle
/// independent of how the bytes are rendered.
public enum TerminalEvent: Equatable {
    /// OSC 133;A: the shell is about to draw a prompt.
    case promptStart
    /// OSC 133;B: the prompt is drawn and input is expected.
    case inputStart
    /// OSC 9001: the command line the shell is about to run.
    case commandText(String)
    /// OSC 133;C: the command has started and output follows.
    case execStart
    /// OSC 133;D: the command finished, with its exit code and captured output.
    case commandFinished(exitCode: Int32?, output: String)
    /// The alternate screen buffer was activated (a full-screen TUI started).
    case enterAlternateScreen
    /// The alternate screen buffer was left (a full-screen TUI exited).
    case exitAlternateScreen
}
