import PotionCore
import SwiftUI

/// A pixel black cat that reacts to the command lifecycle. It never overlaps
/// live text; it lives in its own nook. It never mocks the reader: a failed
/// command reads as a shared problem to look at, not judgment.
///
/// The cat itself never moves. State changes swap frames instantly, and the only
/// motion is a slow opacity pulse on the eyes while a command runs, which is
/// dropped entirely under Reduce Motion.
struct MascotView: View {
    let state: MascotState

    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    private var furColor: Color { Color(red: 0.09, green: 0.06, blue: 0.13) }

    var body: some View {
        ZStack {
            ears
            head
            eyes
            extras
        }
        .frame(width: 56, height: 56)
        .onAppear { pulse = true }
        // Frames swap instantly. Without this the whole cat animates between
        // states and appears to bounce in and out of its nook.
        .animation(nil, value: state)
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
        .offset(y: isAirplaneEars ? -11 : -18)
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
            .offset(y: 4)
    }

    // MARK: Eyes

    private var eyes: some View {
        HStack(spacing: 12) {
            eye
            eye
        }
        .offset(y: 2)
    }

    @ViewBuilder
    private var eye: some View {
        switch state {
        case .idle:
            Capsule().fill(theme.palette.accentSoft).frame(width: 8, height: 2)
        case .typing:
            Circle().fill(theme.palette.accentSoft).frame(width: 7, height: 7)
        case .running:
            Circle()
                .fill(theme.palette.accentSoft)
                .frame(width: 7, height: 7)
                .opacity(reduceMotion ? 1 : (pulse ? 0.45 : 1))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                    value: pulse
                )
        case .success:
            Chevron().stroke(theme.palette.success, lineWidth: 2).frame(width: 9, height: 5)
        case .failure:
            Circle().fill(theme.palette.accentSoft).frame(width: 7, height: 7)
        }
    }

    @ViewBuilder
    private var extras: some View {
        switch state {
        case .success:
            Image(systemName: "sparkle")
                .font(.system(size: 9))
                .foregroundStyle(theme.palette.accent)
                .offset(x: 22, y: -18)
        case .failure:
            // A small, gentle mouth. Never a frown aimed at the reader.
            Capsule().fill(theme.palette.textSecondary).frame(width: 8, height: 2).offset(y: 15)
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

    var body: some View {
        HStack(spacing: 10) {
            MascotView(state: state)
            Text(caption)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
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
