import SwiftUI

/// The composer docked under the terminal: a focus indicator strip above the
/// input field. In later phases the live subtitle bar sits between them.
struct InputBarView: View {
    @ObservedObject var controller: TerminalController

    private var passthrough: Bool {
        controller.inputSink == .terminal
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            focusStrip
            Divider()
            CommandInputBar(controller: controller)
                .frame(height: 24)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .opacity(passthrough ? 0.4 : 1)
        }
    }

    private var focusStrip: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(passthrough ? Color.orange : Color.green)
                .frame(width: 7, height: 7)
            Text(passthrough ? passthroughReason : "Ready for a command")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: controller.toggleManualPassthrough) {
                Text(passthrough ? "Return to input" : "Send keys to terminal")
                    .font(.caption)
            }
            .buttonStyle(.link)
            .keyboardShortcut("t", modifiers: [.command, .shift])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
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
