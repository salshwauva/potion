import Foundation

/// The mascot is a pure function of the command lifecycle. This enum is the
/// swappable data that art is keyed to. Success and failure are transient beats
/// the host holds briefly before settling back to idle.
public enum MascotState: String, Equatable {
    case idle
    case typing
    case running
    case success
    case failure

    /// The steady-state mascot for the given inputs. Outcome beats (success and
    /// failure) are applied by the host on top of this classification.
    public static func classify(isRunning: Bool, isAlternateScreen: Bool, draftEmpty: Bool) -> MascotState {
        if isRunning || isAlternateScreen { return .running }
        return draftEmpty ? .idle : .typing
    }
}
