import SwiftUI

/// The composer docked under the terminal: a focus indicator strip above the
/// input field. In later phases the live subtitle bar sits between them.
struct InputBarView: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    private var passthrough: Bool {
        controller.inputSink == .terminal
    }

    var body: some View {
        VStack(spacing: 0) {
            SubtitleBar(controller: controller)
            Divider()
            focusStrip
            Divider()
            CommandInputBar(controller: controller, fontSize: theme.scaled(13))
                .frame(height: theme.scaled(24))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .opacity(passthrough ? 0.4 : 1)
        }
        .background(theme.palette.windowChrome)
    }

    private var focusStrip: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(passthrough ? theme.palette.running : theme.palette.success)
                .frame(width: 7, height: 7)
                .shadow(color: (passthrough ? theme.palette.running : theme.palette.success).opacity(0.8), radius: 3)
            
            Text(passthrough ? passthroughReason : statusText)
                .font(theme.font(11, weight: .medium))
                .foregroundStyle(theme.palette.textSecondary)
                .lineLimit(1)
            
            Spacer()

            if !passthrough && controller.isCompletionVisible {
                shortcutPill("Tab", label: "Complete")
            }

            if !passthrough && !controller.draft.isEmpty {
                shortcutPill("Return", label: "Execute")
            }

            Button(action: controller.toggleManualPassthrough) {
                Text(passthrough ? "Return to input" : "Direct terminal")
                    .font(theme.font(11))
            }
            .buttonStyle(.potionLink)
            .keyboardShortcut("t", modifiers: [.command, .shift])
            
            shortcutPill("⌘⇧T", label: nil)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }

    private func shortcutPill(_ keys: String, label: String?) -> some View {
        HStack(spacing: 4) {
            Text(keys)
                .font(theme.font(10, weight: .semibold, mono: true))
                .foregroundStyle(theme.palette.textPrimary)
            if let label {
                Text(label)
                    .font(theme.font(10))
                    .foregroundStyle(theme.palette.textTertiary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 5).fill(theme.palette.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(theme.palette.divider, lineWidth: 1))
    }

    private var statusText: String {
        if controller.isCompletionVisible, !controller.ghostText.isEmpty {
            return "Tab to complete"
        }
        return "Ready for a command"
    }

    private var passthroughReason: String {
        if controller.isAlternateScreen {
            return "A full-screen program is running, keys go to it"
        }
        if controller.isRunningCommand {
            return "A command is running, keys go to it"
        }
        return "Keys go to the terminal"
    }
}
