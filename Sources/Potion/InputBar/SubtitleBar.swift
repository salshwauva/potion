import PotionCore
import SwiftUI

/// Renders a ``Subtitle`` as flowing text. Known phrases read in the normal
/// color; honestly-unknown phrases are dimmed and italic so the reader can tell
/// the difference at a glance. Shared by the live bar and the History Panel.
struct SubtitleText: View {
    let subtitle: Subtitle
    var font: Font = .callout

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        Text(attributed)
            .font(font)
            .textSelection(.enabled)
    }

    private var attributed: AttributedString {
        var result = AttributedString()
        for (index, phrase) in subtitle.phrases.enumerated() {
            if index > 0 { result.append(separator) }
            var run = AttributedString(phrase.text)
            switch phrase.confidence {
            case .known:
                run.foregroundColor = theme.palette.textPrimary
            case .unknown:
                run.foregroundColor = theme.palette.textSecondary
                run.font = font.italic()
            }
            result.append(run)
        }
        return result
    }

    private var separator: AttributedString {
        var run = AttributedString(" · ")
        run.foregroundColor = theme.palette.textTertiary
        return run
    }
}

/// The live subtitle bar: the translation of the command being typed, or the
/// frozen translation of the command just run.
struct SubtitleBar: View {
    @ObservedObject var controller: TerminalController
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("subtitle")
                .font(theme.chromeFont(size: 8))
                .foregroundStyle(theme.palette.rim)
            if !controller.liveSubtitle.isEmpty {
                SubtitleText(subtitle: controller.liveSubtitle)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 11)
        .background(theme.palette.windowChrome)
        .overlay(alignment: .top) {
            Rectangle().fill(theme.palette.rim.opacity(0.42)).frame(height: 1)
        }
    }
}
