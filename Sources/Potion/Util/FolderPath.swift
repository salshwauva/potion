import AppKit
import Foundation
import SwiftUI

/// Resolving and opening folder paths that appear in Potion's own interface.
/// Only existing directories are treated as links; files and missing paths are
/// left as plain text.
enum FolderPath {
    /// Extracts a filesystem path from a raw working-directory string, which may
    /// be an OSC 7 `file://host/path` URI or a plain path.
    static func filesystemPath(from raw: String) -> String {
        if raw.hasPrefix("file://"), let url = URL(string: raw) {
            return url.path
        }
        return raw
    }

    /// Home-shortened path for display.
    static func display(from raw: String) -> String {
        let path = filesystemPath(from: raw)
        let home = NSHomeDirectory()
        if path == home { return "~" }
        if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
        return path
    }

    /// Whether the raw working directory points at a real folder.
    static func isFolder(_ raw: String) -> Bool {
        directoryURL(atPath: filesystemPath(from: raw)) != nil
    }

    /// The folder a command token points at, resolved against a base directory,
    /// or nil when it is not an existing directory.
    static func folderURL(token: String, base: String) -> URL? {
        var path = token
        if path.hasPrefix("~") {
            path = NSString(string: path).expandingTildeInPath
        } else if !path.hasPrefix("/") {
            path = NSString(string: base).appendingPathComponent(path)
        }
        return directoryURL(atPath: NSString(string: path).standardizingPath)
    }

    /// Opens a folder in Finder. Ignores anything that is not a directory.
    static func open(_ raw: String) {
        guard let url = directoryURL(atPath: filesystemPath(from: raw)) else { return }
        NSWorkspace.shared.open(url)
    }

    private static func directoryURL(atPath path: String) -> URL? {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
}

extension View {
    /// Shows the pointing-hand cursor while hovering, marking a view as a link.
    func linkCursor() -> some View {
        onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}
