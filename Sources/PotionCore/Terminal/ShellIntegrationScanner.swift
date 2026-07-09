import Foundation

/// A resumable state machine that observes the raw PTY byte stream and extracts
/// shell integration events. It never modifies the stream: the host feeds every
/// byte to the terminal emulator for rendering and, in parallel, to this scanner
/// for tracking.
///
/// The scanner recognizes a small, fixed set of control sequences:
///   - OSC 133 semantic prompt markers (A, B, C, D with optional exit code)
///   - OSC 9001 command-line reports (base64 encoded)
///   - CSI DEC private mode switches for the alternate screen (47, 1047, 1049)
///
/// All other bytes are treated as content. Content that arrives between an
/// execution start (133;C) and completion (133;D) is captured, with escape
/// sequences removed, into a bounded buffer for the error rule engine.
///
/// State persists across `feed` calls, so control sequences split across reads
/// are handled correctly without a separate carry buffer.
public final class ShellIntegrationScanner {
    private enum State {
        case normal
        case escape
        case osc
        case oscEscape
        case csi
        case string // DCS, SOS, PM, APC: consumed and dropped
        case stringEscape
    }

    private var state: State = .normal
    private var oscPayload: [UInt8] = []
    private var csiPayload: [UInt8] = []

    private var capturing = false
    private var captureBytes: [UInt8] = []
    private let maxCaptureBytes: Int

    public private(set) var isAlternateScreen = false

    private static let esc: UInt8 = 0x1b
    private static let bel: UInt8 = 0x07
    private static let backslash: UInt8 = 0x5c

    public init(maxCaptureBytes: Int = 64 * 1024) {
        self.maxCaptureBytes = max(1, maxCaptureBytes)
    }

    /// Feeds a chunk of PTY bytes and returns the events it produced.
    @discardableResult
    public func feed(_ slice: ArraySlice<UInt8>) -> [TerminalEvent] {
        var events: [TerminalEvent] = []
        var i = slice.startIndex
        let end = slice.endIndex

        while i < end {
            let byte = slice[i]
            switch state {
            case .normal:
                if byte == Self.esc {
                    state = .escape
                    i += 1
                } else {
                    // Copy a run of plain content in one step for throughput.
                    var j = i
                    while j < end && slice[j] != Self.esc {
                        j += 1
                    }
                    if capturing {
                        appendCapture(slice[i..<j])
                    }
                    i = j
                }

            case .escape:
                switch byte {
                case 0x5d: // ]
                    state = .osc
                    oscPayload.removeAll(keepingCapacity: true)
                case 0x5b: // [
                    state = .csi
                    csiPayload.removeAll(keepingCapacity: true)
                case 0x50, 0x58, 0x5e, 0x5f: // P (DCS), X (SOS), ^ (PM), _ (APC)
                    state = .string
                default:
                    // Short two-byte escape. Drop it and resume.
                    state = .normal
                }
                i += 1

            case .osc:
                if byte == Self.bel {
                    finishOSC(into: &events)
                    state = .normal
                    i += 1
                } else if byte == Self.esc {
                    state = .oscEscape
                    i += 1
                } else {
                    oscPayload.append(byte)
                    i += 1
                }

            case .oscEscape:
                if byte == Self.backslash {
                    finishOSC(into: &events) // terminated by ESC backslash
                    state = .normal
                    i += 1
                } else {
                    // Malformed terminator. Close the OSC and reprocess this byte.
                    finishOSC(into: &events)
                    state = .normal
                }

            case .csi:
                if byte >= 0x40 && byte <= 0x7e {
                    finishCSI(finalByte: byte, into: &events)
                    state = .normal
                    i += 1
                } else {
                    csiPayload.append(byte)
                    i += 1
                }

            case .string:
                if byte == Self.bel {
                    state = .normal
                    i += 1
                } else if byte == Self.esc {
                    state = .stringEscape
                    i += 1
                } else {
                    i += 1
                }

            case .stringEscape:
                if byte == Self.backslash {
                    state = .normal
                    i += 1
                } else {
                    state = .string
                }
            }
        }

        return events
    }

    private func appendCapture(_ bytes: ArraySlice<UInt8>) {
        captureBytes.append(contentsOf: bytes)
        // Amortized trim: keep memory near the bound without an O(n) removal per byte.
        if captureBytes.count > maxCaptureBytes * 2 {
            captureBytes.removeFirst(captureBytes.count - maxCaptureBytes)
        }
    }

    private func boundedCaptureString() -> String {
        let start = captureBytes.count > maxCaptureBytes
            ? captureBytes.index(captureBytes.startIndex, offsetBy: captureBytes.count - maxCaptureBytes)
            : captureBytes.startIndex
        return String(decoding: captureBytes[start...], as: UTF8.self)
    }

    private func finishOSC(into events: inout [TerminalEvent]) {
        defer { oscPayload.removeAll(keepingCapacity: true) }
        let payload = String(decoding: oscPayload, as: UTF8.self)
        guard let semi = payload.firstIndex(of: ";") else { return }
        let codeString = payload[payload.startIndex..<semi]
        guard let code = Int(codeString) else { return }
        let rest = String(payload[payload.index(after: semi)...])

        switch code {
        case 133:
            let parts = rest.split(separator: ";", omittingEmptySubsequences: false)
            guard let marker = parts.first else { return }
            switch marker {
            case "A":
                events.append(.promptStart)
            case "B":
                events.append(.inputStart)
            case "C":
                capturing = true
                captureBytes.removeAll(keepingCapacity: true)
                events.append(.execStart)
            case "D":
                let exitCode = parts.count > 1 ? Int32(parts[1]) : nil
                let output = boundedCaptureString()
                capturing = false
                captureBytes.removeAll(keepingCapacity: false)
                events.append(.commandFinished(exitCode: exitCode, output: output))
            default:
                break
            }
        case 9001:
            if let data = Data(base64Encoded: rest),
               let text = String(data: data, encoding: .utf8) {
                events.append(.commandText(text))
            }
        default:
            break
        }
    }

    private func finishCSI(finalByte: UInt8, into events: inout [TerminalEvent]) {
        defer { csiPayload.removeAll(keepingCapacity: true) }
        // Alternate screen switches are DEC private modes: ESC [ ? <n> h/l
        guard csiPayload.first == 0x3f else { return } // '?'
        guard finalByte == 0x68 || finalByte == 0x6c else { return } // h or l
        let body = String(decoding: csiPayload.dropFirst(), as: UTF8.self)
        let modes = body.split(separator: ";").compactMap { Int($0) }
        let touchesAltScreen = modes.contains(where: { $0 == 47 || $0 == 1047 || $0 == 1049 })
        guard touchesAltScreen else { return }

        if finalByte == 0x68 {
            if !isAlternateScreen {
                isAlternateScreen = true
                events.append(.enterAlternateScreen)
            }
        } else {
            if isAlternateScreen {
                isAlternateScreen = false
                events.append(.exitAlternateScreen)
            }
        }
    }
}
