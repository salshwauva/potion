import Foundation

/// Shared logic layer for the Potion app. Holds the tokenizer, spec walker,
/// subtitle renderer, syntax table, rule engine, and terminal parsers. Kept
/// free of AppKit so it can be unit tested without a running app.
public enum PotionCore {
    /// Semantic version of the core logic layer, independent of the app bundle.
    public static let version = "0.1.0"
}
