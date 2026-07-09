import AppKit
import SwiftTerm

/// A `LocalProcessTerminalView` that mirrors the raw PTY byte stream to an
/// observer before rendering it. The stream is never altered: `super` renders
/// every byte exactly as received, and the observer tracks command lifecycle in
/// parallel.
final class PotionTerminalView: LocalProcessTerminalView {
    var onRawData: ((ArraySlice<UInt8>) -> Void)?

    override func dataReceived(slice: ArraySlice<UInt8>) {
        onRawData?(slice)
        super.dataReceived(slice: slice)
    }
}
