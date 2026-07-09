import Foundation

public struct FileEntry: Equatable {
    public var name: String
    public var isDirectory: Bool

    public init(name: String, isDirectory: Bool) {
        self.name = name
        self.isDirectory = isDirectory
    }
}

/// Lists directory contents for path completion. Abstracted so the engine can be
/// tested without touching the filesystem.
public protocol FileLister {
    /// Returns entries in `path`. `path` is already resolved to an absolute or
    /// cwd-relative directory. Returns an empty list when the path is unreadable.
    func entries(inDirectory path: String) -> [FileEntry]
}
