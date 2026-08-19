import AppKit
import PotionCore
import SwiftUI

/// The pot artwork, loaded once.
///
/// Optional on purpose: with no render in the bundle the nook falls back to the
/// cat, so a missing asset costs the look and never the app.
enum CauldronArtwork {
    static let pot: NSImage? = {
        guard let url = Bundle.main.url(forResource: "cauldron", withExtension: "png", subdirectory: "art"),
              let image = NSImage(contentsOf: url)
        else { return nil }
        // The file is drawn at twice the size it is shown at, so halving the
        // point size lands one image pixel on one device pixel.
        image.size = NSSize(width: image.size.width / 2, height: image.size.height / 2)
        return image
    }()

    /// The mouth of the pot, in fractions of the artwork, measured off the
    /// render. The brew is placed against this, so a new render needs these four
    /// numbers re-measured and nothing else.
    static let mouth = CGRect(x: 0.181, y: 0.072, width: 0.634, height: 0.112)
}

/// A cauldron that reacts to the command lifecycle.
///
/// The pot never travels. The brew carries the state: still while nothing is
/// happening, stirred while a command is being typed, boiling while it runs, and
/// blown out once when it fails, which leaves the pot on its side until the next
/// command. Failure is loud for one beat and then quiet, because a failed
/// command is a thing to look at, not a scolding.
///
/// Motion runs off `TimelineView(.animation)` rather than a repeating animation
/// on a state flag. Continuous time is what makes a bubble rise, swell and pop
/// on its own clock, and the schedule pauses itself the moment the pot is at
/// rest so an idle terminal costs nothing.
struct CauldronMascot: View {
    let state: MascotState

    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Drives the one-shot blast: 0 before it, 1 once it has fully expanded.
    @State private var blast: Double = 0
    /// Whether the pot is currently lying over.
    @State private var toppled = false

    /// Big enough for the brew to read. Below about 140 the mouth is a dozen
    /// points tall and every liquid detail collapses into a green line.
    private let width: CGFloat = 160
    private var height: CGFloat { width * 189 / 216 }

    private var isLive: Bool {
        !reduceMotion && (state == .running || state == .typing)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            hearth

            // The pot and what it spills share one box, so the puddle is placed
            // against the pot's own feet rather than against the headroom above
            // it.
            ZStack(alignment: .bottom) {
                ZStack {
                    pot
                    brew
                }
            // A lean, not a cartwheel, and pivoted on the left foot it tips
            // over. Rotating about the bottom centre instead swings the far
            // corner below the baseline and drops the pot onto its own caption,
            // which is exactly what it did before this anchor.
            .rotationEffect(.degrees(toppled ? -19 : 0), anchor: .bottomLeading)
            .scaleEffect(toppled ? 0.9 : 1, anchor: .bottomLeading)
                .offset(x: toppled ? width * 0.10 : 0, y: toppled ? 6 : 0)

                spill
            }
            .frame(width: width, height: height)

            blastRing
        }
        // The pot stands on the floor of a taller box. The headroom above it is
        // what the blast ring and the fall need; reserving it here is what keeps
        // either of them off the caption below.
        .frame(width: width, height: height + 58, alignment: .bottom)
        .onAppear { settle(into: state) }
        .onChange(of: state) { _, new in settle(into: new) }
        .accessibilityElement()
        .accessibilityLabel(label)
    }

    // MARK: - Pot

    @ViewBuilder
    private var pot: some View {
        if let image = CauldronArtwork.pot {
            Image(nsImage: image)
                .resizable()
                .interpolation(.none)
                .antialiased(false)
        }
    }

    /// The fire under the legs. Lit only while something is cooking, and lighter
    /// on the pale skins, where embers read heavier for the same opacity.
    private var hearth: some View {
        RadialGradient(
            colors: [theme.palette.sparkle.opacity(hearthOpacity), .clear],
            center: UnitPoint(x: 0.5, y: 0.93),
            startRadius: 0,
            endRadius: width * 0.42
        )
    }

    private var hearthOpacity: Double {
        guard state == .running, !toppled else { return 0 }
        return theme.mode == .dark ? 0.30 : 0.20
    }

    // MARK: - Brew

    private var brew: some View {
        GeometryReader { proxy in
            let rect = mouthRect(in: proxy.size)

            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isLive)) { context in
                let time = context.date.timeIntervalSinceReferenceDate

                ZStack {
                    surface(in: rect, time: time)

                    if state == .typing {
                        swirl(in: rect, time: time)
                    }

                    if state == .running {
                        bubbles(in: rect, time: time)
                    }
                }
                .opacity(level)
            }
        }
        .allowsHitTesting(false)
    }

    private func mouthRect(in size: CGSize) -> CGRect {
        let mouth = CauldronArtwork.mouth
        return CGRect(
            x: mouth.minX * size.width,
            y: mouth.minY * size.height,
            width: mouth.width * size.width,
            height: mouth.height * size.height
        ).insetBy(dx: 1.5, dy: 1)
    }

    /// The liquid itself, built from three shades of the skin's own colour
    /// rather than one hue at three alphas. Alpha only ever thins a colour
    /// toward whatever is behind it, which is why the old surface read as a
    /// tinted disc: depth needs a darker pigment at the back and a lighter one
    /// where the light lands, not more transparency.
    private func surface(in rect: CGRect, time: Double) -> some View {
        let swell = state == .running ? 1 + 0.085 * sin(time * 3.4) : 1

        return ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: liquidDeep, location: 0),
                            .init(color: liquidBase, location: 0.55),
                            .init(color: liquidBase.mixed(with: liquidDeep, amount: 0.25), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    // The pool of light on the front left, where a pot this deep
                    // catches the room.
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [liquidBright.opacity(0.85), .clear],
                                center: UnitPoint(x: 0.36, y: 0.62),
                                startRadius: 0,
                                endRadius: rect.width * 0.42
                            )
                        )
                }
                .overlay {
                    // The iron shading the liquid it holds.
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [liquidDeep.opacity(0.9), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
                .overlay {
                    Ellipse()
                        .strokeBorder(liquidDeep.mixed(with: .black, amount: 0.45).opacity(0.75), lineWidth: 1.5)
                }

            // The near edge catches the light that the far edge does not, which
            // is most of what separates a liquid from a coloured disc.
            Ellipse()
                .trim(from: 0.02, to: 0.48)
                .stroke(liquidBright.opacity(0.75), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: rect.width * 0.92, height: rect.height * 0.86)
                .blur(radius: 0.6)

            Ellipse()
                .fill(liquidBright.opacity(0.5))
                .frame(width: rect.width * 0.30, height: rect.height * 0.26)
                .blur(radius: 1.4)
                .offset(x: -rect.width * 0.16, y: -rect.height * 0.16)
        }
        .frame(width: rect.width, height: rect.height)
        .scaleEffect(y: swell)
        .position(x: rect.midX, y: rect.midY)
    }

    /// Stirring: glints carried around the surface on elliptical tracks, the
    /// inner ones faster, plus a shadow trailing the near side. Arcs drawn as
    /// circles and squashed to the mouth collapse into slivers at this size, so
    /// the motion is carried by what the light does instead.
    private func swirl(in rect: CGRect, time: Double) -> some View {
        ZStack {
            ForEach(Array(stirTracks.enumerated()), id: \.offset) { _, track in
                let angle = time * track.speed + track.offset
                Ellipse()
                    .fill(liquidBright.opacity(track.light))
                    .frame(width: rect.width * track.length, height: rect.height * 0.3)
                    .blur(radius: 0.8)
                    .offset(
                        x: cos(angle) * rect.width * track.radius,
                        y: sin(angle) * rect.height * track.radius
                    )
            }

            Ellipse()
                .fill(Color.black.opacity(0.22))
                .frame(width: rect.width * 0.44, height: rect.height * 0.42)
                .blur(radius: 1.6)
                .offset(
                    x: cos(time * 1.6 + .pi) * rect.width * 0.22,
                    y: sin(time * 1.6 + .pi) * rect.height * 0.22
                )
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
    }

    /// The boil, played broad: fat domes shoulder up through the surface,
    /// wobble, and burst into a ring and a spray of droplets, with steam curling
    /// off the top. Each bubble keeps its own period so the pot never pulses in
    /// time with itself.
    private func bubbles(in rect: CGRect, time: Double) -> some View {
        ZStack {
            ForEach(Array(bubbleSpots.enumerated()), id: \.offset) { _, spot in
                let cycle = (time / spot.period + spot.offset).truncatingRemainder(dividingBy: 1)
                bubble(spot, cycle: cycle, in: rect)
            }

            steam(in: rect, time: time)
        }
    }

    /// One bubble, from swell to burst. The rise eases out so it slows as it
    /// reaches the surface, and the burst is quick, because a slow pop reads as
    /// a fade rather than a pop.
    @ViewBuilder
    private func bubble(_ spot: BubbleSpot, cycle: Double, in rect: CGRect) -> some View {
        let x = rect.minX + rect.width * spot.x

        if cycle < burstPoint {
            let rise = easeOut(cycle / burstPoint)
            let size = spot.size * (0.3 + 0.7 * rise)
            let squash = 1 + 0.10 * sin(cycle * 34)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [liquidBright, liquidBase.opacity(0.6)],
                            center: UnitPoint(x: 0.34, y: 0.28),
                            startRadius: 0,
                            endRadius: max(size, 1)
                        )
                    )
                Circle()
                    .strokeBorder(liquidBright.mixed(with: .white, amount: 0.55), lineWidth: 1.6)
                Circle()
                    .fill(liquidBright.mixed(with: .white, amount: 0.75))
                    .frame(width: size * 0.22, height: size * 0.22)
                    .offset(x: -size * 0.22, y: -size * 0.24)
            }
            .frame(width: size, height: size)
            .scaleEffect(x: squash, y: 2 - squash)
            .position(x: x, y: rect.midY + rect.height * spot.depth - rect.height * 0.34 * rise)
        } else {
            let burst = (cycle - burstPoint) / (1 - burstPoint)
            let ring = spot.size * (1 + burst * 2.4)

            ZStack {
                Circle()
                    .strokeBorder(liquidBright.mixed(with: .white, amount: 0.5).opacity(0.85 * (1 - burst)), lineWidth: 2.2 * (1 - burst) + 0.4)
                    .frame(width: ring, height: ring * 0.7)

                ForEach(0..<4, id: \.self) { drop in
                    let angle = -.pi * (0.82 - Double(drop) * 0.21)
                    Circle()
                        .fill(liquidBright.mixed(with: .white, amount: 0.45).opacity(0.9 * (1 - burst)))
                        .frame(width: spot.size * 0.2, height: spot.size * 0.2)
                        .offset(
                            x: cos(angle) * spot.size * 1.5 * burst,
                            y: sin(angle) * spot.size * 1.5 * burst + spot.size * burst * burst * 1.4
                        )
                }
            }
            .position(x: x, y: rect.midY + rect.height * spot.depth - rect.height * 0.34)
        }
    }

    /// Steam off the top. Three puffs on a long cycle, drifting as they climb,
    /// which is what sells a boil at a glance from across the screen.
    private func steam(in rect: CGRect, time: Double) -> some View {
        ForEach(Array(steamPuffs.enumerated()), id: \.offset) { _, puff in
            let cycle = (time / puff.period + puff.offset).truncatingRemainder(dividingBy: 1)
            let climb = easeOut(cycle)
            // Tinted with the brew rather than white: white vapour vanishes on
            // the pale skins, and steam coming off a green pot reads green.
            Circle()
                .fill(liquidBright.opacity(0.42 * pow(1 - cycle, 1.6)))
                .frame(width: puff.size * (0.4 + climb * 0.8), height: puff.size * (0.4 + climb * 0.8))
                .blur(radius: 1.6)
                .position(
                    x: rect.minX + rect.width * puff.x + sin(climb * 5 + puff.offset * 6) * rect.width * 0.05,
                    y: rect.midY - rect.height * (0.7 + climb * 1.9)
                )
        }
    }

    /// Where in a bubble's cycle it stops rising and blows.
    private var burstPoint: Double { 0.78 }

    private func easeOut(_ t: Double) -> Double {
        1 - pow(1 - min(max(t, 0), 1), 2.2)
    }

    // MARK: - Failure

    /// The blast: one ring of pressure and a scatter of droplets, fired once as
    /// the pot goes over.
    private var blastRing: some View {
        ZStack {
            Circle()
                .strokeBorder(liquidBright.opacity(0.85 * (1 - blast)), lineWidth: 3)
                .frame(width: width * (0.25 + blast * 1.5), height: width * (0.25 + blast * 1.5))

            ForEach(0..<8, id: \.self) { index in
                let angle = Double(index) / 8 * 2 * .pi - .pi / 2
                Circle()
                    .fill(liquidBase.opacity(0.9 * (1 - blast)))
                    .frame(width: 4.5, height: 4.5)
                    .offset(
                        x: cos(angle) * width * 0.5 * blast,
                        y: sin(angle) * width * 0.34 * blast - width * 0.05
                    )
            }
        }
        .offset(y: -(height + 58) * 0.12)
        .opacity(blast > 0 && blast < 1 ? 1 : 0)
        .allowsHitTesting(false)
    }

    /// What the pot threw out, pooled where it landed.
    private var spill: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [liquidDeep.opacity(0.75), liquidDeep.opacity(0.15)],
                    center: .center,
                    startRadius: 0,
                    endRadius: width * 0.3
                )
            )
            .frame(width: width * (toppled ? 0.55 : 0.1), height: height * 0.09)
            .opacity(toppled ? 1 : 0)
            .position(x: width * 0.30, y: height * 0.97)
            .allowsHitTesting(false)
    }

    // MARK: - Transitions

    /// Moves the pot into the posture the state calls for. Failure is the only
    /// state with a beat to it: blow out, tip over, then hold.
    private func settle(into state: MascotState) {
        guard state == .failure else {
            blast = 0
            guard toppled else { return }
            if reduceMotion {
                toppled = false
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { toppled = false }
            }
            return
        }

        guard !reduceMotion else {
            toppled = true
            return
        }

        blast = 0
        withAnimation(.easeOut(duration: 0.5)) { blast = 1 }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.52).delay(0.08)) { toppled = true }
    }

    // MARK: - Palette

    /// The brew is always the skin's own colour. Semantic green and red were in
    /// here for the outcome states and read as somebody else's palette dropped
    /// into the pot; the outcome is carried by how the brew behaves and by the
    /// caption beside it.
    private var liquidBase: Color {
        switch state {
        case .idle: return theme.palette.accentSoft.mixed(with: theme.palette.accent, amount: 0.35)
        case .typing: return theme.palette.accentSoft
        case .running: return theme.palette.accent
        case .success: return theme.palette.accent.mixed(with: theme.palette.sparkle, amount: 0.45)
        case .failure: return theme.palette.accent.mixed(with: theme.palette.terminalBackground, amount: 0.35)
        }
    }

    /// The pigment at the back of the pot and in the shadow of the rim.
    private var liquidDeep: Color {
        liquidBase.mixed(with: theme.palette.terminalBackground, amount: 0.55)
    }

    /// Where the light lands: bubbles, glints, steam and the near edge.
    private var liquidBright: Color {
        liquidBase.mixed(with: theme.palette.sparkle, amount: 0.5)
    }

    /// How much the brew asserts itself. It never drains between commands, so
    /// rest is a still surface rather than an empty pot; only a boil-over
    /// empties it.
    private var level: Double {
        if toppled { return 0 }
        switch state {
        case .idle: return 0.8
        case .typing: return 0.92
        case .running: return 1
        case .success: return 0.95
        case .failure: return 0
        }
    }

    private var label: String {
        switch state {
        case .idle: return "Cauldron, at rest"
        case .typing: return "Cauldron, being stirred"
        case .running: return "Cauldron, boiling"
        case .success: return "Cauldron, settled"
        case .failure: return "Cauldron, boiled over"
        }
    }
}

/// One bubble's place on the surface and its rhythm.
struct BubbleSpot {
    let x: CGFloat
    let depth: CGFloat
    let size: CGFloat
    let period: Double
    let offset: Double
}

/// Fewer bubbles than a real boil, each much larger, which is the trade a
/// cartoon makes: legible shapes over accurate physics.
private let bubbleSpots: [BubbleSpot] = [
    BubbleSpot(x: 0.24, depth: 0.16, size: 13, period: 1.15, offset: 0.0),
    BubbleSpot(x: 0.44, depth: -0.18, size: 18, period: 1.45, offset: 0.38),
    BubbleSpot(x: 0.63, depth: 0.22, size: 11, period: 0.95, offset: 0.66),
    BubbleSpot(x: 0.80, depth: -0.10, size: 15, period: 1.30, offset: 0.19)
]

/// The puffs coming off the top: where each starts, how big it gets, how long it
/// takes to climb, and where in that climb it begins.
private let steamPuffs: [(x: CGFloat, size: CGFloat, period: Double, offset: Double)] = [
    (0.34, 12, 2.6, 0.0),
    (0.52, 16, 3.2, 0.45),
    (0.68, 10, 2.2, 0.72)
]

/// The tracks the stirring glints ride: how far out, how long the smear, how
/// bright, how fast, and where each one starts.
private let stirTracks: [(radius: CGFloat, length: CGFloat, light: Double, speed: Double, offset: Double)] = [
    (0.30, 0.30, 0.46, 2.6, 0),
    (0.20, 0.22, 0.34, 3.4, 2.1),
    (0.36, 0.18, 0.24, 2.1, 4.0)
]
