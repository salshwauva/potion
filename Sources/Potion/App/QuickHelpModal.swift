import SwiftUI

/// Quick Help Modal overlay providing immediate learning guidance, terminal command concepts,
/// and keyboard shortcuts. Triggered via ⌘H or the top chrome header help button.
struct QuickHelpModal: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    controller.showQuickHelpModal = false
                }

            VStack(alignment: .leading, spacing: 16) {
                headerView
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        introSection
                        howItWorksSection
                        shortcutsSection
                    }
                }
                Divider()
                footerView
            }
            .padding(20)
            .frame(width: 520, height: 480)
            .background(RoundedRectangle(cornerRadius: 12).fill(theme.palette.panelBackground))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.palette.rim.opacity(0.5), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        }
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "sparkles.tv")
                .font(.system(size: 20))
                .foregroundStyle(theme.palette.accent)
            Text("Potion Terminal & Learning Guide")
                .font(theme.headingFont(size: 16))
                .foregroundStyle(theme.palette.textPrimary)
            Spacer()
            Button {
                controller.showQuickHelpModal = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.palette.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome to Potion!")
                .font(theme.font(14, weight: .semibold))
                .foregroundStyle(theme.palette.accentSoft)
            Text("Potion is a real zsh terminal enhanced with live plain-English command translations, intelligent suggestions, and interactive cheatsheets to help you master terminal fluency naturally while doing real work.")
                .font(theme.font(12))
                .foregroundStyle(theme.palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.palette.cardBackground))
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HOW TO LEARN WITH POTION")
                .font(theme.labelFont(size: 10))
                .tracking(theme.labelTracking)
                .foregroundStyle(theme.palette.rim)

            VStack(alignment: .leading, spacing: 8) {
                conceptRow(step: "1", title: "Type in the Input Bar", desc: "Compose commands with full syntax highlighting and instant ghost autocomplete.")
                conceptRow(step: "2", title: "Read Live Translations", desc: "Watch the Subtitle bar and Translator tab break down flags, arguments, and subcommands.")
                conceptRow(step: "3", title: "Explore Smart Suggestions", desc: "Open the Suggestions tab (⌘B) for context-aware commands tailored to your active directory.")
                conceptRow(step: "4", title: "Browse 4,900+ Command Docs", desc: "Use the Help tab or search bar to inspect tldr examples and insert them with 1-click.")
            }
        }
    }

    private func conceptRow(step: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(theme.font(11, weight: .bold, mono: true))
                .frame(width: 20, height: 20)
                .background(Circle().fill(theme.palette.accent.opacity(0.2)))
                .foregroundStyle(theme.palette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.font(12, weight: .semibold))
                    .foregroundStyle(theme.palette.textPrimary)
                Text(desc)
                    .font(theme.font(11))
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ESSENTIAL KEYBOARD SHORTCUTS")
                .font(theme.labelFont(size: 10))
                .tracking(theme.labelTracking)
                .foregroundStyle(theme.palette.rim)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    shortcutBadge("⌘H")
                    Text("Toggle Quick Help Modal").font(theme.font(11)).foregroundStyle(theme.palette.textSecondary)
                    shortcutBadge("⌘B")
                    Text("Toggle Learning Sidebar").font(theme.font(11)).foregroundStyle(theme.palette.textSecondary)
                }
                GridRow {
                    shortcutBadge("Tab")
                    Text("Accept Autocomplete").font(theme.font(11)).foregroundStyle(theme.palette.textSecondary)
                    shortcutBadge("⌘⇧T")
                    Text("Send Keys Direct to Terminal").font(theme.font(11)).foregroundStyle(theme.palette.textSecondary)
                }
                GridRow {
                    shortcutBadge("Up/Down")
                    Text("Cycle Command History").font(theme.font(11)).foregroundStyle(theme.palette.textSecondary)
                    shortcutBadge("⌘,")
                    Text("Appearance & Theme Settings").font(theme.font(11)).foregroundStyle(theme.palette.textSecondary)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(theme.palette.cardBackground))
        }
    }

    private func shortcutBadge(_ keys: String) -> some View {
        Text(keys)
            .font(theme.font(10, weight: .bold, mono: true))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(theme.palette.cardBackgroundRaised))
            .foregroundStyle(theme.palette.accentSoft)
    }

    private var footerView: some View {
        HStack {
            Spacer()
            Button("Got it, let's learn!") {
                controller.showQuickHelpModal = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }
}
