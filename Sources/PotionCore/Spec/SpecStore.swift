import Foundation

/// Decodes bundled command specifications. Kept separate from the app so specs
/// can be loaded from any data source, including test fixtures.
public enum SpecStore {
    public static func decode(_ data: Data) throws -> [CommandSpec] {
        try JSONDecoder().decode([CommandSpec].self, from: data)
    }
}
