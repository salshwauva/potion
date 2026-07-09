import Foundation

/// A gentle, literal explanation of a failed command, plus concrete fixes shown
/// as real commands. Cards supplement the raw terminal output; they never hide
/// it.
public struct ErrorCard: Equatable {
    public var title: String
    public var explanation: String
    public var fixes: [ErrorFix]

    public init(title: String, explanation: String, fixes: [ErrorFix] = []) {
        self.title = title
        self.explanation = explanation
        self.fixes = fixes
    }
}

public struct ErrorFix: Equatable {
    /// What the fix does, in plain words.
    public var description: String
    /// The command to run. Inserted into the input bar, never executed directly.
    public var command: String

    public init(description: String, command: String) {
        self.description = description
        self.command = command
    }
}
