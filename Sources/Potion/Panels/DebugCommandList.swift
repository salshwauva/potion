import PotionCore
import SwiftUI

/// P1 verification surface: a live list of tracked commands with exit code,
/// duration, working directory, and captured output. Later phases replace this
/// with the History Panel described in the spec.
struct DebugCommandList: View {
    @ObservedObject var controller: TerminalController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if controller.records.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .frame(minWidth: 280)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Command tracking (debug)")
                .font(.headline)
            Text(controller.currentDirectory ?? "cwd unknown")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.head)
            if controller.isAlternateScreen {
                Text("alternate screen active")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("Run a command to see it tracked here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(controller.records.reversed()) { record in
                    DebugCommandRow(record: record)
                }
            }
            .padding(10)
        }
    }
}

private struct DebugCommandRow: View {
    let record: CommandRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                statusDot
                Text(record.command.isEmpty ? "(no command text)" : record.command)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(2)
            }
            HStack(spacing: 10) {
                if let exit = record.exitCode {
                    Text("exit \(exit)")
                } else if record.status == .running {
                    Text("running")
                }
                if let duration = record.duration {
                    Text(String(format: "%.2fs", duration))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !record.capturedOutput.isEmpty {
                Text(outputTail(record.capturedOutput))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
    }

    private var statusDot: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private var color: Color {
        switch record.status {
        case .running: return .yellow
        case .success: return .green
        case .failure: return .red
        }
    }

    private func outputTail(_ text: String, lines: Int = 3) -> String {
        let trimmed = text.split(separator: "\n", omittingEmptySubsequences: false)
        return trimmed.suffix(lines).joined(separator: "\n")
    }
}
