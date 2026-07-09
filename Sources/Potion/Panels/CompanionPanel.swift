import SwiftUI

/// The right-hand companion panel. It holds the History and Docs sections, with
/// the Error explainer arriving in a later phase. It shows Docs automatically
/// while a documented command is being typed, and returns to History otherwise.
struct CompanionPanel: View {
    @ObservedObject var controller: TerminalController

    enum Section: Hashable {
        case history
        case docs
    }

    @State private var section: Section = .history

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                Text("History").tag(Section.history)
                Text("Docs").tag(Section.docs)
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
            }
        }
        .frame(minWidth: 320)
        .onChange(of: controller.docsCommand) { _, newValue in
            section = (newValue != nil) ? .docs : .history
        }
    }
}
