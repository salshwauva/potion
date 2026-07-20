import Combine
import PotionCore
import SwiftUI

/// A pixel black cat that reacts to the command lifecycle. It never overlaps
/// live text; it lives in its own nook. It never mocks the reader: a failed
/// command reads as a shared problem to look at, not judgment.
///
/// All motion happens inside the cat: the tail sways, the eyes blink and track,
/// the ears flatten. The body itself never moves, so the cat never appears to
/// bounce in or out of its nook. Everything is dropped under Reduce Motion,
/// which falls back to a static frame per state.
///
/// The continuous motion is driven by `withAnimation` on a single shared phase
/// rather than an `.animation(_:value:)` modifier: a `repeatForever` animation
/// attached that way stops the affected view from drawing at all.
struct MascotView: View {
    let state: MascotState

    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Shared oscillation driving the tail, the eye pulse, and the sparkle.
    @State private var phase = false
    /// Briefly true to close the eyes.
    @State private var blinking = false

    private let blinkTimer = Timer.publish(every: 3.4, on: .main, in: .common).autoconnect()

    private var furColor: Color { Color(red: 0.09, green: 0.06, blue: 0.13) }

    var body: some View {
        ZStack {
            tail
            ears
            head
            eyes
            extras
        }
        .frame(width: 68, height: 58)
        // Frames swap instantly. Without this the whole cat animates between
        // states and appears to bounce in and out of its nook.
        .animation(nil, value: state)
        .onAppear { startMotion() }
        .onChange(of: state) { _, _ in startMotion() }
        .onReceive(blinkTimer) { _ in
            guard !reduceMotion, state != .success, state != .idle else { return }
            blinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) { blinking = false }
        }
    }

    /// Restarts the shared oscillation so a state change picks up its own tempo.
    private func startMotion() {
        phase = false
        guard !reduceMotion, let period = motionPeriod else { return }
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: period).repeatForever(autoreverses: true)) {
                phase = true
            }
        }
    }

    /// How fast the cat moves in each state. Nil holds it still.
    private var motionPeriod: Double? {
        switch state {
        case .idle: return 2.6
        case .typing: return 1.5
        case .running: return 0.65
        case .success: return 0.55
        case .failure: return nil
        }
    }

    // MARK: Tail

    /// The tail carries most of the cat's mood: a slow sway at rest, a quick
    /// flick while a command runs, and tucked down when something failed.
    private var tail: some View {
        Capsule()
            .fill(furColor)
            .overlay(Capsule().stroke(theme.palette.rim, lineWidth: 1.5))
            .frame(width: 9, height: 27)
            .rotationEffect(.degrees(tailAngle + swayDelta), anchor: .bottom)
            .offset(x: 25, y: 9)
    }

    /// Resting angle of the tail. A worried cat tucks it down.
    private var tailAngle: Double {
        state == .failure ? 38 : -14
    }

    private var swayDelta: Double {
        guard !reduceMotion, motionPeriod != nil else { return 0 }
        return phase ? 15 : -15
    }

    // MARK: Ears

    /// Ears flatten sideways when a command fails: the classic "airplane ears" a
    /// cat makes when something is off. Upright the rest of the time.
    private var isAirplaneEars: Bool { state == .failure }

    private var ears: some View {
        HStack(spacing: 18) {
            ear.rotationEffect(.degrees(isAirplaneEars ? -72 : 0), anchor: .bottom)
            ear.rotationEffect(.degrees(isAirplaneEars ? 72 : 0), anchor: .bottom)
        }
        .offset(x: -6, y: isAirplaneEars ? -11 : -18)
    }

    private var ear: some View {
        Triangle()
            .fill(furColor)
            .overlay(Triangle().stroke(theme.palette.rim, lineWidth: 1.5))
            .frame(width: 16, height: 14)
    }

    private var head: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(furColor)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.palette.rim, lineWidth: 1.5))
            .frame(width: 44, height: 38)
            .offset(x: -6, y: 4)
    }

    // MARK: Eyes

    /// Closed while dozing, and for the moment of a blink.
    private var eyesClosed: Bool {
        if state == .idle { return true }
        return blinking
    }

    private var eyes: some View {
        HStack(spacing: 12) {
            eye
            eye
        }
        .offset(x: -6, y: 2)
    }

    @ViewBuilder
    private var eye: some View {
        if state == .success {
            Chevron().stroke(theme.palette.success, lineWidth: 2).frame(width: 9, height: 5)
        } else if eyesClosed {
            Capsule().fill(theme.palette.accentSoft).frame(width: 8, height: 2)
        } else {
            Circle()
                .fill(theme.palette.accentSoft)
                .frame(width: 7, height: 7)
                // While typing the eyes drift, as if reading along the line.
                .offset(x: eyeDrift)
                .opacity(eyeOpacity)
        }
    }

    private var eyeDrift: CGFloat {
        guard !reduceMotion, state == .typing else { return 0 }
        return phase ? 1.7 : -1.7
    }

    private var eyeOpacity: Double {
        guard !reduceMotion, state == .running else { return 1 }
        return phase ? 0.45 : 1
    }

    @ViewBuilder
    private var extras: some View {
        switch state {
        case .success:
            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(theme.palette.accent)
                .opacity(reduceMotion ? 1 : (phase ? 1 : 0.3))
                .offset(x: 16, y: -18)
        case .failure:
            // A small, gentle mouth. Never a frown aimed at the reader.
            Capsule().fill(theme.palette.textSecondary).frame(width: 8, height: 2).offset(x: -6, y: 15)
        default:
            EmptyView()
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct Chevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
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
