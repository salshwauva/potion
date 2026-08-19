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
                header
            }
            .frame(minWidth: 320)
            .background(canvas)
            .overlay(alignment: .leading) {
                // The panel's own lit edge against the terminal well beside it.
                Rectangle()
                    .fill(theme.palette.rim.opacity(0.16))
                    .frame(width: 1)
            }
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

    /// The mascot's alcove and the section switcher, on a shelf a rung above the
    /// canvas so the sections below read as sitting under it.
    private var header: some View {
        VStack(spacing: 0) {
            MascotNook(state: controller.mascotState)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .panelTrack(radius: 12)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 10)

            PixelTabBar(selection: $section)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
        }
        .background(
            LinearGradient(
                colors: [
                    theme.palette.windowChrome,
                    theme.palette.windowChrome.mixed(with: theme.palette.panelBackground, amount: 0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.palette.rim.opacity(0.14))
                .frame(height: 1)
        }
        // The shelf casts onto the section under it, which is what separates the
        // two without a rule between them.
        .background(alignment: .bottom) {
            LinearGradient(
                colors: [Color.black.opacity(theme.mode == .dark ? 0.30 : 0.12), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: PanelDepth.shelfShadow)
            .offset(y: PanelDepth.shelfShadow)
            .allowsHitTesting(false)
        }
    }

    /// The canvas: the panel rung, dropping toward the well at the bottom so the
    /// column has a floor rather than ending flat.
    private var canvas: some View {
        LinearGradient(
            colors: [
                theme.palette.panelBackground,
                theme.palette.panelBackground,
                theme.palette.panelBackground.mixed(with: theme.palette.terminalBackground, amount: 0.35)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
