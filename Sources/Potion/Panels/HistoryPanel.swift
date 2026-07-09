import AppKit
import PotionCore
import SwiftUI

/// The companion panel's History section: one card per tracked command, newest
/// first. Cards show status, exit code, duration, and captured output, with
/// actions to copy or re-run. Subtitles are added in a later phase.
struct HistoryPanel: View {
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
        .frame(minWidth: 300)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("History")
                .font(.headline)
            Text(controller.currentDirectory.map(shortenPath) ?? "working directory unknown")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("Commands you run appear here, each with its result.")
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
                    HistoryCard(record: record) {
                        controller.insertIntoInput(record.command)
                    }
                }
            }
            .padding(10)
        }
    }

    private func shortenPath(_ path: String) -> String {
        let home = NSHomeDirectory()
        if path == home { return "~" }
        if path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

private struct HistoryCard: View {
    let record: CommandRecord
    let onReRun: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                statusBadge
                Text(record.command.isEmpty ? "(no command text)" : record.command)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            metadata
            actions
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.05)))
    }

    private var statusBadge: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        switch record.status {
        case .running: return .yellow
        case .success: return .green
        case .failure: return .red
        }
    }

    private var metadata: some View {
        HStack(spacing: 10) {
            switch record.status {
            case .running:
                Text("running")
            case .success:
                Text("succeeded")
            case .failure:
                Text(record.exitCode.map { "failed, exit \($0)" } ?? "failed")
                    .foregroundStyle(.red)
            }
            if let duration = record.duration {
                Text(formatDuration(duration))
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Copy command") { copy(record.command) }
            if !record.capturedOutput.isEmpty {
                Button("Copy output") { copy(record.capturedOutput) }
            }
            Button("Re-run", action: onReRun)
        }
        .font(.caption)
        .buttonStyle(.link)
    }

    private func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 1 {
            return String(format: "%.0f ms", duration * 1000)
        }
        return String(format: "%.2f s", duration)
    }
}
