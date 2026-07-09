import PotionCore
import SwiftUI

/// Renders a ``Subtitle`` as flowing text. Known phrases read in the normal
/// color; honestly-unknown phrases are dimmed and italic so the reader can tell
/// the difference at a glance. Shared by the live bar and the History Panel.
struct SubtitleText: View {
    let subtitle: Subtitle
    var font: Font = .callout

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
                run.foregroundColor = .primary
            case .unknown:
                run.foregroundColor = .secondary
                run.font = font.italic()
            }
            result.append(run)
        }
        return result
    }

    private var separator: AttributedString {
        var run = AttributedString(" · ")
        run.foregroundColor = Color(nsColor: .tertiaryLabelColor)
        return run
    }
}

/// The live subtitle bar: the translation of the command being typed, or the
/// frozen translation of the command just run.
struct SubtitleBar: View {
    @ObservedObject var controller: TerminalController

    var body: some View {
        Group {
            if controller.liveSubtitle.isEmpty {
                Text("The plain-English meaning of your command appears here.")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            } else {
                SubtitleText(subtitle: controller.liveSubtitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
