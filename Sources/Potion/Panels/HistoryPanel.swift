import AppKit
import PotionCore
import SwiftUI

/// The companion panel's History section: one card per tracked command, newest
/// first. Cards show status, exit code, duration, and captured output, with
/// actions to copy or re-run. Subtitles are added in a later phase.
struct HistoryPanel: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("History")
                .font(theme.headingFont(size: 14))
                .foregroundStyle(theme.palette.textPrimary)
            if let cwd = controller.currentDirectory, FolderPath.isFolder(cwd) {
                Button {
                    FolderPath.open(cwd)
                } label: {
                    Text(FolderPath.display(from: cwd))
                        .font(theme.font(12, mono: true))
                        .foregroundStyle(theme.palette.accentSoft)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
                .buttonStyle(.plain)
                .help("Open in Finder")
                .linkCursor()
            } else {
                Text("working directory unknown")
                    .font(theme.font(11))
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            PixelGlyph(glyph: theme.skin.motif[0], cell: 3)
                .opacity(0.85)
            Text("Commands you run appear here, each with its result.")
                .font(theme.font(13))
                .foregroundStyle(theme.palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(controller.records.reversed()) { record in
                    HistoryCard(
                        record: record,
                        subtitle: controller.subtitle(for: record.command),
                        canExplain: controller.hasErrorCard(for: record.id),
                        onReRun: { controller.insertIntoInput(record.command) },
                        onExplain: { controller.focusError(record.id) }
                    )
                }
            }
            .padding(10)
        }
    }

}

private struct HistoryCard: View {
    let record: CommandRecord
    let subtitle: Subtitle
    let canExplain: Bool
    let onReRun: () -> Void
    let onExplain: () -> Void

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                statusBadge
                if record.command.isEmpty {
                    Text("(no command text)")
                        .font(theme.font(13, mono: true))
                        .foregroundStyle(theme.palette.textSecondary)
                } else {
                    CommandText(command: record.command, cwd: record.cwd)
                        .lineLimit(2)
                }
            }
            if !subtitle.isEmpty {
                SubtitleText(subtitle: subtitle, size: 11)
            }
            metadata
            actions
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 7).fill(theme.palette.cardBackground))
    }

    private var statusBadge: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        switch record.status {
        case .running: return theme.palette.running
        case .success: return theme.palette.success
        case .failure: return theme.palette.failure
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
                    .foregroundStyle(theme.palette.failure)
            }
            if let duration = record.duration {
                Text(formatDuration(duration))
            }
        }
        .font(theme.font(11))
        .foregroundStyle(theme.palette.textSecondary)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button("Copy command") { copy(record.command) }
            if !record.capturedOutput.isEmpty {
                Button("Copy output") { copy(record.capturedOutput) }
            }
            Button("Re-run", action: onReRun)
            if canExplain {
                Button("Explain", action: onExplain)
            }
        }
        .font(theme.font(11))
        .buttonStyle(.potionLink)
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
