import SwiftUI

/// The right-hand companion panel: the mascot nook on top, then the History,
/// Docs, and Error sections. It shows Docs automatically while a documented
/// command is typed, and jumps to Errors when a command fails.
struct CompanionPanel: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    enum Section: Hashable {
        case history
        case docs
        case errors
    }

    @State private var section: Section = .history

    var body: some View {
        VStack(spacing: 0) {
            MascotNook(state: controller.mascotState)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 6)

            Picker("", selection: $section) {
                Text("History").tag(Section.history)
                Text("Docs").tag(Section.docs)
                Text("Errors").tag(Section.errors)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            Divider()

            switch section {
            case .history:
                HistoryPanel(controller: controller)
            case .docs:
                DocsPanel(controller: controller)
            case .errors:
                ErrorsPanel(controller: controller)
            }
        }
        .frame(minWidth: 320)
        .background(theme.palette.panelBackground)
        .onChange(of: controller.docsCommand) { _, newValue in
            if newValue != nil { section = .docs }
        }
        .onChange(of: controller.focusedErrorId) { _, newValue in
            if newValue != nil { section = .errors }
        }
    }
}
