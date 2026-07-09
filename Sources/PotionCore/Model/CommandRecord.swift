import Foundation

/// One executed command in the shell timeline, assembled from OSC 133 markers.
/// The record starts in `.running` at execution and is finalized when the shell
/// reports completion with an exit code.
public struct CommandRecord: Identifiable, Equatable {
    public enum Status: Equatable {
        case running
        case success
        case failure
    }

    public let id: UUID
    /// The command line as reported by the shell preexec hook.
    public var command: String
    /// Exit code once the command has finished. Nil while running or when the
    /// shell reported completion without a code.
    public var exitCode: Int32?
    public var startedAt: Date
    public var finishedAt: Date?
    /// Working directory captured at the moment the command began.
    public var cwd: String?
    /// Bounded, escape-stripped tail of the command's merged output.
    public var capturedOutput: String
    public var status: Status

    public init(
        id: UUID = UUID(),
        command: String = "",
        exitCode: Int32? = nil,
        startedAt: Date,
        finishedAt: Date? = nil,
        cwd: String? = nil,
        capturedOutput: String = "",
        status: Status = .running
    ) {
        self.id = id
        self.command = command
        self.exitCode = exitCode
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.cwd = cwd
        self.capturedOutput = capturedOutput
        self.status = status
    }

    /// Wall-clock duration once finished.
    public var duration: TimeInterval? {
        guard let finishedAt else { return nil }
        return finishedAt.timeIntervalSince(startedAt)
    }
}
