import Combine
import PotionCore
import SwiftUI

/// A pixel black cat that reacts to the command lifecycle. It never overlaps
/// live text; it lives in its own nook. It never mocks the reader: a failed
/// command reads as a shared problem to look at, not judgment.
///
/// The artwork is a pixel sprite (see ``CatSprite``). Motion is deliberately
/// small: the cat breathes with a couple of points of rise and fall, and blinks.
/// Its body never travels, so it cannot appear to bounce in or out of the nook.
/// Everything is dropped under Reduce Motion, which leaves a static frame.
///
/// The oscillation is driven by `withAnimation` on a shared phase rather than an
/// `.animation(_:value:)` modifier: a `repeatForever` animation attached that
/// way stops the affected view from drawing at all.
struct MascotView: View {
    let state: MascotState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Shared oscillation driving the breath and the running pulse.
    @State private var phase = false
    /// Briefly true to close the eyes.
    @State private var blinking = false

    private let blinkTimer = Timer.publish(every: 3.4, on: .main, in: .common).autoconnect()

    var body: some View {
        PixelCat(rows: CatSprite.rows(for: state, blinking: blinking), cell: 3)
            .opacity(pulseOpacity)
            .offset(y: bobOffset)
            .animation(nil, value: state)
            .onAppear { startMotion() }
            .onChange(of: state) { _, _ in startMotion() }
            .onReceive(blinkTimer) { _ in
                guard !reduceMotion, state != .idle, state != .success else { return }
                blinking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) { blinking = false }
            }
    }

    /// Restarts the oscillation so a state change picks up its own tempo.
    private func startMotion() {
        phase = false
        guard !reduceMotion, let period = motionPeriod else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: period).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }

    /// How fast the cat breathes in each state. Nil holds it still.
    private var motionPeriod: Double? {
        switch state {
        case .idle: return 2.6
        case .typing: return 1.5
        case .running: return 0.65
        case .success: return 0.55
        case .failure: return nil
        }
    }

    /// Small on purpose: a couple of points reads as breathing, more reads as
    /// bouncing. A worried cat goes still entirely.
    private var bobAmplitude: CGFloat {
        switch state {
        case .idle: return 1.5
        case .typing: return 1.5
        case .running: return 2
        case .success: return 2.5
        case .failure: return 0
        }
    }

    private var bobOffset: CGFloat {
        guard !reduceMotion, motionPeriod != nil else { return 0 }
        return phase ? -bobAmplitude : bobAmplitude
    }

    /// A faint pulse while a command runs, so the cat reads as busy.
    private var pulseOpacity: Double {
        guard !reduceMotion, state == .running else { return 1 }
        return phase ? 0.82 : 1
    }
}

/// The mascot with a plain, gentle caption. The caption uses ordinary words,
/// never themed vocabulary.
struct MascotNook: View {
    let state: MascotState

    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        HStack(spacing: 10) {
            MascotView(state: state)
            Text(caption)
                .font(theme.chromeFont(size: 10))
                .foregroundStyle(theme.palette.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var caption: String {
        switch state {
        case .idle: return "Ready when you are."
        case .typing: return "Watching along."
        case .running: return "Working on it."
        case .success: return "That worked."
        case .failure: return "Something to look at together."
        }
    }
}
