import Foundation
import PotionCore

/// Loads bundled tldr pages. osx pages take precedence over common ones, which
/// matches how tldr resolves platform-specific documentation.
final class TldrLibrary {
    private let osxDir: URL?
    private let commonDir: URL?
    private(set) var names: [String] = []

    init() {
        let base = Bundle.main.url(forResource: "tldr", withExtension: nil)
        osxDir = base?.appendingPathComponent("osx")
        commonDir = base?.appendingPathComponent("common")
        names = buildIndex()
    }

    func hasPage(named name: String) -> Bool {
        url(for: name) != nil
    }

    func page(named name: String) -> TldrPage? {
        guard let url = url(for: name),
              let markdown = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return TldrParser.parse(markdown, name: name)
    }

    /// Command names matching the query, prefix matches first.
    func search(_ query: String, limit: Int = 50) -> [String] {
        let needle = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return Array(names.prefix(limit)) }
        let matches = names.filter { $0.contains(needle) }
        let ranked = matches.sorted { lhs, rhs in
            let lp = lhs.hasPrefix(needle), rp = rhs.hasPrefix(needle)
            if lp != rp { return lp }
            return lhs < rhs
        }
        return Array(ranked.prefix(limit))
    }

    private func url(for name: String) -> URL? {
        let fm = FileManager.default
        if let osx = osxDir?.appendingPathComponent("\(name).md"), fm.fileExists(atPath: osx.path) {
            return osx
        }
        if let common = commonDir?.appendingPathComponent("\(name).md"), fm.fileExists(atPath: common.path) {
            return common
        }
        return nil
    }

    private func buildIndex() -> [String] {
        var set = Set<String>()
        for dir in [commonDir, osxDir].compactMap({ $0 }) {
            guard let items = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { continue }
            for file in items where file.hasSuffix(".md") {
                set.insert(String(file.dropLast(3)))
            }
        }
        return set.sorted()
    }
}
