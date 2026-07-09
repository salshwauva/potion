import Foundation

/// Shell-style history navigation for the input bar. Up recalls older entries,
/// Down returns toward the draft that was being composed. The draft in progress
/// is preserved so navigating away and back does not lose it.
public struct InputHistory {
    /// Entries ordered oldest first, newest last.
    private var entries: [String] = []
    /// Index into `entries` while browsing, or nil when editing the live draft.
    private var browseIndex: Int?
    private var savedDraft: String = ""

    public init() {}

    /// Replaces the set of recallable entries. Consecutive duplicates and empty
    /// lines are dropped so navigation feels like a shell history.
    public mutating func setEntries(_ commands: [String]) {
        var cleaned: [String] = []
        for command in commands {
            let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if cleaned.last != trimmed {
                cleaned.append(trimmed)
            }
        }
        entries = cleaned
    }

    /// Whether the user is currently browsing history rather than editing.
    public var isBrowsing: Bool { browseIndex != nil }

    /// Recalls the previous (older) entry. Returns nil when there is nothing
    /// older to show.
    public mutating func previous(currentDraft: String) -> String? {
        guard !entries.isEmpty else { return nil }
        switch browseIndex {
        case nil:
            savedDraft = currentDraft
            browseIndex = entries.count - 1
        case .some(let index) where index > 0:
            browseIndex = index - 1
        default:
            return nil // already at the oldest entry
        }
        return entries[browseIndex!]
    }

    /// Moves toward newer entries. Past the newest entry, restores the draft.
    public mutating func next(currentDraft: String) -> String? {
        guard let index = browseIndex else { return nil }
        if index < entries.count - 1 {
            browseIndex = index + 1
            return entries[browseIndex!]
        } else {
            browseIndex = nil
            return savedDraft
        }
    }

    /// Clears browsing state, for use after a submission.
    public mutating func reset() {
        browseIndex = nil
        savedDraft = ""
    }
}
