import Foundation
import PotionCore

/// Native path completion backend. Lists a directory's contents with FileManager.
struct FileManagerLister: FileLister {
    func entries(inDirectory path: String) -> [FileEntry] {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: path) else { return [] }
        return names.map { name in
            var isDir: ObjCBool = false
            let full = (path as NSString).appendingPathComponent(name)
            fm.fileExists(atPath: full, isDirectory: &isDir)
            return FileEntry(name: name, isDirectory: isDir.boolValue)
        }
    }
}
