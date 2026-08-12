import SwiftUI

/// The right-hand companion panel: the mascot nook and section tabs pinned to
/// the top as a safe-area inset, then the History, Docs, or Error section
/// filling the rest. It shows Docs automatically while a documented command is
/// typed, and jumps to Errors when a command fails.
struct CompanionPanel: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    enum Section: Hashable {
        case translator
        case suggestions
        case help
        case errors
    }

    @State private var section: Section = .translator

    var body: some View {
        section(for: section)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    MascotNook(state: controller.mascotState)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .padding(.bottom, 6)
                    PixelTabBar(selection: $section)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                    Divider()
                }
                .background(theme.palette.panelBackground)
            }
            .frame(minWidth: 320)
            .background(theme.palette.panelBackground)
            .onChange(of: controller.docsCommand) { _, newValue in
                if newValue != nil { section = .help }
            }
            .onChange(of: controller.focusedErrorId) { _, newValue in
                if newValue != nil { section = .errors }
            }
            .onChange(of: controller.draft) { _, newValue in
                if !newValue.isEmpty && section == .suggestions {
                    section = .translator
                }
            }
    }

    @ViewBuilder
    private func section(for section: Section) -> some View {
        switch section {
        case .translator:
            TranslatorPanel(controller: controller)
        case .suggestions:
            SuggestionsPanel(controller: controller)
        case .help:
            HelpPanel(controller: controller)
        case .errors:
            ErrorsPanel(controller: controller)
        }
    }
}
