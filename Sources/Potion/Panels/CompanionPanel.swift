import SwiftUI

/// The right-hand companion panel. It holds the History, Docs, and Error
/// sections. It shows Docs automatically while a documented command is typed,
/// and jumps to Errors when a command fails.
struct CompanionPanel: View {
    @ObservedObject var controller: TerminalController

    enum Section: Hashable {
        case history
        case docs
        case errors
    }

    @State private var section: Section = .history

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                Text("History").tag(Section.history)
                Text("Docs").tag(Section.docs)
                Text("Errors").tag(Section.errors)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(8)
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
        .onChange(of: controller.docsCommand) { _, newValue in
            if newValue != nil { section = .docs }
        }
        .onChange(of: controller.focusedErrorId) { _, newValue in
            if newValue != nil { section = .errors }
        }
    }
}
