import PotionCore
import SwiftUI

/// The companion panel's Docs section. It shows the tldr page for the command
/// being typed, with a search field to browse others. Every example has an
/// Insert button that places the command in the input bar without running it,
/// and each example carries its own subtitle.
struct DocsPanel: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    @State private var searchText = ""
    @State private var selectedCommand: String?

    private var shownCommand: String? {
        selectedCommand ?? controller.docsCommand
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
            Divider()
            content
        }
        .onChange(of: controller.docsCommand) { _, _ in
            // Typing a new command overrides a manual selection.
            selectedCommand = nil
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(theme.palette.textTertiary)
            TextField("Search commands", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(10)
    }

    @ViewBuilder
    private var content: some View {
        if !searchText.isEmpty {
            searchResults
        } else if let command = shownCommand {
            if let page = controller.tldrLibrary.page(named: command) {
                pageView(page)
            } else {
                missingPage(for: command)
            }
        } else {
            commonCommands
        }
    }

    /// The default view: a browsable list of the commands Potion knows, each
    /// with its plain-English description. Selecting one opens its page.
    private var commonCommands: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text("COMMON COMMANDS")
                    .font(theme.labelFont(size: 10))
                    .tracking(theme.labelTracking)
                    .foregroundStyle(theme.palette.rim)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                ForEach(controller.commonCommands, id: \.name) { spec in
                    Button {
                        selectedCommand = spec.name
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(spec.name)
                                .font(theme.font(13, mono: true))
                                .foregroundStyle(theme.palette.textPrimary)
                                .frame(width: 68, alignment: .leading)
                            Text(spec.description ?? "")
                                .font(theme.font(12))
                                .foregroundStyle(theme.palette.textSecondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.25)
                }
            }
        }
    }

    /// A command Potion knows but has no bundled page for.
    private func missingPage(for command: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(command)
                .font(theme.font(20, weight: .semibold, mono: true))
                .foregroundStyle(theme.palette.textPrimary)
            if let spec = controller.commonCommands.first(where: { $0.names.contains(command) }),
               let description = spec.description {
                Text(description)
                    .font(theme.font(13))
                    .foregroundStyle(theme.palette.textSecondary)
            }
            Text("No bundled documentation page for this one yet.")
                .font(theme.font(11))
                .foregroundStyle(theme.palette.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    private var searchResults: some View {
        let results = controller.tldrLibrary.search(searchText)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(results, id: \.self) { name in
                    Button {
                        selectedCommand = name
                        searchText = ""
                    } label: {
                        Text(name)
                            .font(theme.font(13, mono: true))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.3)
                }
                if results.isEmpty {
                    Text("No command matches \"\(searchText)\".")
                        .font(theme.font(13))
                        .foregroundStyle(theme.palette.textSecondary)
                        .padding()
                }
            }
        }
    }

    private func pageView(_ page: TldrPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(page.name)
                        .font(theme.font(20, weight: .semibold, mono: true))
                        .foregroundStyle(theme.palette.textPrimary)
                    Text(page.description)
                        .font(theme.font(13))
                        .foregroundStyle(theme.palette.textSecondary)
                }
                ForEach(Array(page.examples.enumerated()), id: \.offset) { _, example in
                    exampleView(example)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func exampleView(_ example: TldrExample) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(example.description)
                .font(theme.font(13))
            HStack(alignment: .top, spacing: 8) {
                Text(example.command)
                    .font(theme.font(13, mono: true))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(theme.palette.cardBackground))
                Button("Insert") { controller.insertIntoInput(example.command) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            let subtitle = controller.subtitle(for: example.command)
            if !subtitle.isEmpty {
                SubtitleText(subtitle: subtitle, size: 11)
            }
        }
        .padding(.bottom, 4)
    }

}
