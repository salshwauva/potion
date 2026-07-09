import PotionCore
import SwiftUI

/// The companion panel's Docs section. It shows the tldr page for the command
/// being typed, with a search field to browse others. Every example has an
/// Insert button that places the command in the input bar without running it,
/// and each example carries its own subtitle.
struct DocsPanel: View {
    @ObservedObject var controller: TerminalController

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
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search commands", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(10)
    }

    @ViewBuilder
    private var content: some View {
        if !searchText.isEmpty {
            searchResults
        } else if let command = shownCommand, let page = controller.tldrLibrary.page(named: command) {
            pageView(page)
        } else {
            emptyState
        }
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
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.3)
                }
                if results.isEmpty {
                    Text("No command matches \"\(searchText)\".")
                        .font(.callout)
                        .foregroundStyle(.secondary)
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
                        .font(.system(.title2, design: .monospaced))
                    Text(page.description)
                        .font(.callout)
                        .foregroundStyle(.secondary)
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
                .font(.callout)
            HStack(alignment: .top, spacing: 8) {
                Text(example.command)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                Button("Insert") { controller.insertIntoInput(example.command) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            let subtitle = controller.subtitle(for: example.command)
            if !subtitle.isEmpty {
                SubtitleText(subtitle: subtitle, font: .caption)
            }
        }
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("Type a command to see friendly examples, or search above.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
