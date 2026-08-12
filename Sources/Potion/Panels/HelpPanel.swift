import PotionCore
import SwiftUI

/// The Help Panel: an easy-to-use command cheatsheet, searchable tldr documentation center,
/// and beginner guide for learning terminal commands.
struct HelpPanel: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    @State private var searchText = ""
    @State private var selectedCommand: String?
    @State private var selectedCategory: String = "All"

    private let categories = ["All", "Files", "Search", "Git", "System", "Network"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
            categoryPicker
            Divider()
            contentArea
        }
        .onChange(of: controller.docsCommand) { _, newValue in
            if newValue != nil { selectedCommand = nil }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.palette.textTertiary)
            TextField("Search commands (e.g. grep, git, chmod)...", text: $searchText)
                .textFieldStyle(.plain)
                .font(theme.font(12))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(theme.palette.cardBackground)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(categories, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                        selectedCommand = nil
                    } label: {
                        Text(cat)
                            .font(theme.labelFont(size: 11))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == cat ? theme.palette.accent : theme.palette.cardBackground)
                            )
                            .foregroundStyle(selectedCategory == cat ? theme.palette.terminalBackground : theme.palette.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(theme.palette.panelBackground)
    }

    @ViewBuilder
    private var contentArea: some View {
        if !searchText.isEmpty {
            searchResultsView
        } else if let cmd = selectedCommand ?? controller.docsCommand {
            if let page = controller.tldrLibrary.page(named: cmd) {
                pageDetailView(page)
            } else {
                missingPage(for: cmd)
            }
        } else {
            cheatsheetListView
        }
    }

    private var searchResultsView: some View {
        let matches = controller.tldrLibrary.search(searchText)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(matches, id: \.self) { name in
                    Button {
                        selectedCommand = name
                    } label: {
                        HStack {
                            Text(name)
                                .font(theme.font(13, weight: .semibold, mono: true))
                                .foregroundStyle(theme.palette.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(theme.palette.textTertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().opacity(0.2)
                }
                if matches.isEmpty {
                    Text("No command matching \"\(searchText)\".")
                        .font(theme.font(13))
                        .foregroundStyle(theme.palette.textSecondary)
                        .padding(20)
                }
            }
        }
    }

    private var cheatsheetListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                shortcutsCard

                Text("ESSENTIAL COMMAND CHEATSHEET")
                    .font(theme.labelFont(size: 10))
                    .tracking(theme.labelTracking)
                    .foregroundStyle(theme.palette.rim)

                let specs = filteredSpecs
                ForEach(specs, id: \.name) { spec in
                    Button {
                        selectedCommand = spec.name
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Text(spec.name)
                                .font(theme.font(13, weight: .semibold, mono: true))
                                .foregroundStyle(theme.palette.accent)
                                .frame(width: 80, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(spec.description ?? "")
                                    .font(theme.font(12))
                                    .foregroundStyle(theme.palette.textPrimary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(theme.palette.textTertiary)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 6).fill(theme.palette.cardBackground))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }

    private var shortcutsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KEYBOARD SHORTCUTS")
                .font(theme.labelFont(size: 10))
                .tracking(theme.labelTracking)
                .foregroundStyle(theme.palette.rim)

            VStack(spacing: 6) {
                shortcutRow(keys: "Tab", desc: "Accept autocomplete suggestion")
                shortcutRow(keys: "Return", desc: "Execute command in terminal")
                shortcutRow(keys: "Up / Down", desc: "Browse previous command history")
                shortcutRow(keys: "⌘B", desc: "Toggle right companion sidebar")
                shortcutRow(keys: "⌘H", desc: "Open quick help & cheatsheet modal")
                shortcutRow(keys: "⌘⇧T", desc: "Direct passthrough to terminal")
            }
        }
        .padding(11)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.palette.cardBackground))
    }

    private func shortcutRow(keys: String, desc: String) -> some View {
        HStack {
            Text(keys)
                .font(theme.font(10, weight: .semibold, mono: true))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(theme.palette.cardBackgroundRaised))
                .foregroundStyle(theme.palette.accentSoft)
            Text(desc)
                .font(theme.font(11))
                .foregroundStyle(theme.palette.textSecondary)
            Spacer()
        }
    }

    private var filteredSpecs: [CommandSpec] {
        let all = controller.commonCommands
        switch selectedCategory {
        case "Files":
            return all.filter { ["ls", "cd", "pwd", "mkdir", "cp", "mv", "rm", "chmod", "chown"].contains($0.name) }
        case "Search":
            return all.filter { ["grep", "find", "cat", "less", "head", "tail", "wc"].contains($0.name) }
        case "Git":
            return all.filter { $0.name.hasPrefix("git") }
        case "System":
            return all.filter { ["ps", "top", "kill", "df", "du", "uname", "whoami"].contains($0.name) }
        case "Network":
            return all.filter { ["curl", "ping", "ssh", "netstat", "ifconfig"].contains($0.name) }
        default:
            return all
        }
    }

    private func pageDetailView(_ page: TldrPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    selectedCommand = nil
                } label: {
                    Label("Back to cheatsheet", systemImage: "chevron.left")
                        .font(theme.font(11))
                }
                .buttonStyle(.potionLink)

                VStack(alignment: .leading, spacing: 4) {
                    Text(page.name)
                        .font(theme.font(20, weight: .bold, mono: true))
                        .foregroundStyle(theme.palette.accent)
                    Text(page.description)
                        .font(theme.font(13))
                        .foregroundStyle(theme.palette.textSecondary)
                }

                ForEach(Array(page.examples.enumerated()), id: \.offset) { _, example in
                    exampleCard(example)
                }
            }
            .padding(12)
        }
    }

    private func exampleCard(_ example: TldrExample) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(example.description)
                .font(theme.font(12, weight: .medium))
                .foregroundStyle(theme.palette.textPrimary)

            HStack(alignment: .top, spacing: 8) {
                Text(example.command)
                    .font(theme.font(12, mono: true))
                    .foregroundStyle(theme.palette.accentSoft)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(theme.palette.cardBackground))
                
                Button("Insert") {
                    controller.insertIntoInput(example.command)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            let sub = controller.subtitle(for: example.command)
            if !sub.isEmpty {
                SubtitleText(subtitle: sub, size: 10)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 7).fill(theme.palette.cardBackgroundRaised))
    }

    private func missingPage(for command: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                selectedCommand = nil
            } label: {
                Label("Back to cheatsheet", systemImage: "chevron.left")
                    .font(theme.font(11))
            }
            .buttonStyle(.potionLink)

            Text(command)
                .font(theme.font(18, weight: .bold, mono: true))
                .foregroundStyle(theme.palette.textPrimary)
            Text("No bundled tldr page for \"\(command)\".")
                .font(theme.font(12))
                .foregroundStyle(theme.palette.textSecondary)
        }
        .padding(12)
    }
}
