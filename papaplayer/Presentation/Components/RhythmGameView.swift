import Foundation
import SwiftUI

struct RhythmGameView: View {
    let notes: [RhythmNote]
    let splashes: [HoneySplash]
    let ripples: [HoneyRipple]
    let callouts: [PartyCallout]
    let currentTime: Double
    let score: Int
    let combo: Int
    let highCombo: Int
    let misses: Int
    let fillLevel: Double
    let isLost: Bool
    let laneCount: Int
    let hitZoneRatio: Double
    let colorMode: GameColorMode
    let hitAction: (UUID) -> Void

    private var palette: GamePalette { GamePalette(mode: colorMode) }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                scoreBadge(title: "Score", value: "\(score)")
                scoreBadge(title: "Combo", value: "x\(combo)")
                scoreBadge(title: "Best", value: "x\(highCombo)")
                scoreBadge(title: "Miss", value: "\(misses)")
            }

            GeometryReader { proxy in
                gameArena(size: proxy.size)
            }
            .frame(height: 500)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(palette.cardTint)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.62), lineWidth: 1)
                )
        )
    }

    private func gameArena(size: CGSize) -> some View {
        let palette = palette
        let width = size.width
        let height = size.height
        let laneWidth = width / CGFloat(laneCount)
        let hitY = height * hitZoneRatio
        let honeySurfaceY = height * (1 - CGFloat(min(max(fillLevel, 0), 1)))

        return ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.white.opacity(0.45), lineWidth: 1)
                )

            SpeakerWallBackground(
                fillLevel: fillLevel,
                laneCount: laneCount,
                currentTime: currentTime,
                palette: palette
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            WaterLiquidLayer(
                fillLevel: fillLevel,
                ripples: ripples,
                laneCount: laneCount,
                musicTime: currentTime,
                palette: palette
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            laneDividers(width: width, laneWidth: laneWidth)

            noteLayer(
                laneWidth: laneWidth,
                hitY: hitY,
                arenaHeight: height,
                honeySurfaceY: honeySurfaceY,
                palette: palette
            )
            splashLayer(laneWidth: laneWidth, hitY: hitY, arenaHeight: height, palette: palette)
            calloutLayer(width: width)

            if isLost {
                VStack(spacing: 8) {
                    Text("Flooded")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                    Text("Party got over. Speakers got drowned.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.black.opacity(0.86))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func laneDividers(width: CGFloat, laneWidth: CGFloat) -> some View {
        ForEach(1..<laneCount, id: \.self) { lane in
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1)
                .offset(x: -width / 2 + CGFloat(lane) * laneWidth)
        }
    }

    private func noteLayer(laneWidth: CGFloat, hitY: CGFloat, arenaHeight: CGFloat, honeySurfaceY: CGFloat, palette: GamePalette) -> some View {
        ForEach(notes) { note in
            let rawProgress = (currentTime - note.spawnTime) / note.travelDuration
            if rawProgress > -0.08, rawProgress < 1.3 {
                let seed = noteSeed(note.id)
                let clamped = min(max(rawProgress, 0), 1.2)
                let sticky = stickyProgress(for: clamped, size: note.size, seed: seed, time: currentTime)
                let bubbleSize = CGFloat(note.size)
                let laneX = laneWidth * (CGFloat(note.lane) + 0.5)
                let xJitter = CGFloat(sin(currentTime * 2.6 + seed * 10.0)) * CGFloat(1 - min(clamped, 1)) * 2.2
                let rawY = max(0, min(arenaHeight, CGFloat(sticky) * hitY))
                let submergedDepth = max(0, rawY - honeySurfaceY)
                let normalizedDepth = min(submergedDepth / max(bubbleSize * 3.0, 1), 1)
                let sinkFactor = 1 - normalizedDepth * 0.65
                let yPosition = submergedDepth > 0
                    ? honeySurfaceY + submergedDepth * sinkFactor
                    : rawY
                let submergeRatio = min(max(submergedDepth / max(bubbleSize, 1), 0), 1)
                let spawnAppear = min(max((rawProgress + 0.02) / 0.2, 0), 1)
                let laneEdgePadding = max(18, bubbleSize * 0.62)
                let driftAmplitude = laneWidth * 0.26 * submergeRatio
                let driftSpeed = 1.3 + seed * 1.1
                let driftPhase = seed * .pi * 2.0 + Double(note.lane) * 0.6
                let driftX = CGFloat(sin(currentTime * driftSpeed + driftPhase)) * driftAmplitude
                let laneMinX = CGFloat(note.lane) * laneWidth + laneEdgePadding
                let laneMaxX = CGFloat(note.lane + 1) * laneWidth - laneEdgePadding
                let xPosition = min(max(laneX + xJitter + driftX, laneMinX), laneMaxX)
                let trailHeight = max(16, bubbleSize * CGFloat(0.55 + (1 - min(clamped, 1)) * 0.45))

                FallingWaterBubbleView(
                    bubbleSize: bubbleSize,
                    trailHeight: trailHeight,
                    xPosition: xPosition,
                    yPosition: yPosition,
                    submergeRatio: submergeRatio,
                    spawnAppear: spawnAppear,
                    palette: palette,
                    seed: seed,
                    time: currentTime,
                    onTap: { hitAction(note.id) }
                )
            }
        }
    }

    private func splashLayer(laneWidth: CGFloat, hitY: CGFloat, arenaHeight: CGFloat, palette: GamePalette) -> some View {
        ForEach(splashes) { splash in
            let elapsed = max(0, currentTime - splash.createdTime)
            if elapsed < 0.62 {
                let xPosition = laneWidth * (CGFloat(splash.lane) + 0.5)
                let yPosition = max(0, min(arenaHeight, CGFloat(splash.progress) * hitY))

                WaterSplashBlastView(
                    splashSize: CGFloat(splash.size),
                    elapsed: elapsed,
                    xPosition: xPosition,
                    yPosition: yPosition,
                    palette: palette
                )
            }
        }
    }

    private func calloutLayer(width: CGFloat) -> some View {
        ForEach(callouts) { callout in
            let elapsed = max(0, currentTime - callout.createdTime)
            if elapsed < 2.8 {
                let t = elapsed / 2.8
                let rise = CGFloat(t) * 26
                let opacity = max(0, min(1, (1 - t * 0.95)))

                Text(callout.text)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(opacity))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.38 * opacity), in: Capsule())
                    .position(x: width * 0.5, y: 38 - rise)
            }
        }
    }

    private func scoreBadge(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.black.opacity(0.5))
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.82))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func noteSeed(_ id: UUID) -> Double {
        let scalar = Double(abs(id.uuidString.hashValue % 997))
        return scalar / 997.0
    }

    private func stickyProgress(for progress: Double, size: Double, seed: Double, time: Double) -> Double {
        let clamped = min(max(progress, 0), 1)
        let heavyFactor = min(max((size - 24) / 40, 0), 1)
        let eased = pow(clamped, 1.22 + heavyFactor * 0.22)
        let wobble = sin((clamped * 9.0) + time * 3.2 + seed * 6.0) * 0.012 * (1 - clamped)
        return min(max(eased + wobble, 0), 1.05)
    }
}

private struct GamePalette {
    let bubblePrimary: Color
    let bubbleSecondary: Color
    let cardTint: Color
    let muffleTint: Color
    let liquidTop: Color
    let liquidMid: Color
    let liquidBottom: Color

    init(mode: GameColorMode) {
        switch mode {
        case .yellow:
            bubblePrimary = .yellow
            bubbleSecondary = .orange
            cardTint = .yellow.opacity(0.26)
            muffleTint = Color(red: 0.22, green: 0.16, blue: 0.06)
            liquidTop = Color.yellow.opacity(0.8)
            liquidMid = Color.orange.opacity(0.85)
            liquidBottom = Color(red: 0.95, green: 0.66, blue: 0.15).opacity(0.92)
        case .blue:
            bubblePrimary = .blue
            bubbleSecondary = .cyan
            cardTint = .blue.opacity(0.26)
            muffleTint = Color(red: 0.06, green: 0.14, blue: 0.24)
            liquidTop = Color.blue.opacity(0.8)
            liquidMid = Color.cyan.opacity(0.85)
            liquidBottom = Color(red: 0.18, green: 0.46, blue: 0.88).opacity(0.92)
        }
    }
}

private struct SpeakerWallBackground: View {
    let fillLevel: Double
    let laneCount: Int
    let currentTime: Double
    let palette: GamePalette

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let laneWidth = width / CGFloat(max(laneCount, 1))
            let aliveFactor = max(0, 1 - fillLevel * 1.15)
            let pulse = 1 + CGFloat(sin(currentTime * 5.6)) * 0.035 * aliveFactor

            ZStack {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Canvas { canvas, size in
                    var grill = Path()
                    let spacing: CGFloat = 12
                    var y: CGFloat = 0
                    while y <= size.height {
                        grill.move(to: CGPoint(x: 0, y: y))
                        grill.addLine(to: CGPoint(x: size.width, y: y))
                        y += spacing
                    }
                    canvas.stroke(grill, with: .color(.white.opacity(0.08)), lineWidth: 1)
                }

                ForEach(0..<laneCount, id: \.self) { lane in
                    let centerX = laneWidth * (CGFloat(lane) + 0.5)
                    let mainRadius = min(laneWidth * 0.27, height * 0.13)
                    let subRadius = mainRadius * 0.6

                    VStack(spacing: mainRadius * 0.42) {
                        speakerCone(radius: mainRadius, pulse: pulse, alive: aliveFactor)
                        speakerCone(radius: subRadius, pulse: 1 + (pulse - 1) * 0.7, alive: aliveFactor)
                    }
                    .position(x: centerX, y: height * 0.45)
                }

                palette.muffleTint
                    .opacity(fillLevel * 0.35)
            }
        }
    }

    private func speakerCone(radius: CGFloat, pulse: CGFloat, alive: Double) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.14 + alive * 0.08),
                            .gray.opacity(0.24),
                            .black.opacity(0.62)
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 1.72 * pulse, height: radius * 1.72 * pulse)

            Circle()
                .fill(.black.opacity(0.78))
                .frame(width: radius * 0.44, height: radius * 0.44)
        }
        .opacity(0.75 + alive * 0.25)
    }
}

private struct FallingWaterBubbleView: View {
    let bubbleSize: CGFloat
    let trailHeight: CGFloat
    let xPosition: CGFloat
    let yPosition: CGFloat
    let submergeRatio: CGFloat
    let spawnAppear: Double
    let palette: GamePalette
    let seed: Double
    let time: Double
    let onTap: () -> Void

    var body: some View {
        let visibleTrailHeight = trailHeight * (1 - submergeRatio)
        let bubbleScale = 1 - submergeRatio * 0.24
        let bubbleOpacity = 1 - submergeRatio * 0.45
        let appearOpacity = CGFloat(spawnAppear)
        let appearScale = CGFloat(0.92 + spawnAppear * 0.08)

        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.02),
                            palette.bubblePrimary.opacity(0.12),
                            palette.bubbleSecondary.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: max(8, bubbleSize * 0.27), height: trailHeight)
                .frame(height: max(0, visibleTrailHeight), alignment: .bottom)
                .offset(y: -visibleTrailHeight * 0.48)
                .opacity((1 - submergeRatio) * appearOpacity)

            ForEach(0..<3, id: \.self) { index in
                let phase = time * 4.5 + seed * 8.0 + Double(index) * 0.7
                Circle()
                    .fill(palette.bubblePrimary.opacity(0.42))
                    .frame(width: bubbleSize * (0.08 + CGFloat(index) * 0.04))
                    .offset(
                        x: CGFloat(sin(phase)) * CGFloat(2.2 - Double(index) * 0.4),
                        y: -visibleTrailHeight * (0.16 + CGFloat(index) * 0.17)
                    )
                    .opacity((1 - submergeRatio) * appearOpacity)
            }

            Circle()
                .fill(
                    LinearGradient(
                        colors: [palette.bubblePrimary.opacity(0.95), palette.bubbleSecondary.opacity(0.84)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: bubbleSize, height: bubbleSize)
                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                .shadow(color: palette.bubbleSecondary.opacity(0.4), radius: 8, y: 4)
                .scaleEffect(bubbleScale * appearScale)
                .opacity(bubbleOpacity * appearOpacity)
        }
        .position(x: xPosition, y: yPosition)
        .onTapGesture(perform: onTap)
    }
}

private struct WaterSplashBlastView: View {
    let splashSize: CGFloat
    let elapsed: Double
    let xPosition: CGFloat
    let yPosition: CGFloat
    let palette: GamePalette

    var body: some View {
        let t = elapsed / 0.62

        return ZStack {
            Circle()
                .stroke(.white.opacity(0.95 - t), lineWidth: 2)
                .frame(width: splashSize * CGFloat(1 + t * 0.9), height: splashSize * CGFloat(1 + t * 0.9))
            Circle()
                .stroke(palette.bubblePrimary.opacity(0.85 - t * 0.8), lineWidth: 3)
                .frame(width: splashSize * CGFloat(0.8 + t * 1.3), height: splashSize * CGFloat(0.8 + t * 1.3))
            Circle()
                .fill(palette.bubbleSecondary.opacity(0.35 - t * 0.35))
                .frame(width: splashSize * CGFloat(0.5 + t * 0.8), height: splashSize * CGFloat(0.5 + t * 0.8))

            ForEach(0..<8, id: \.self) { index in
                let angle = (Double(index) / 8.0) * .pi * 2
                let distance = splashSize * CGFloat(0.2 + t * 1.2)
                Circle()
                    .fill(palette.bubblePrimary.opacity(0.95 - t))
                    .frame(width: max(3, splashSize * 0.09), height: max(3, splashSize * 0.09))
                    .offset(
                        x: CGFloat(cos(angle)) * distance,
                        y: CGFloat(sin(angle)) * distance
                    )
            }
        }
        .position(x: xPosition, y: yPosition)
    }
}

private struct WaterLiquidLayer: View {
    let fillLevel: Double
    let ripples: [HoneyRipple]
    let laneCount: Int
    let musicTime: Double
    let palette: GamePalette

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.03, paused: false)) { context in
            let time = context.date.timeIntervalSinceReferenceDate

            Canvas { canvas, size in
                let level = min(max(fillLevel, 0), 1)
                guard level > 0 else { return }

                let baseSurface = size.height * (1 - CGFloat(level))
                let path = honeyPath(
                    size: size,
                    baseSurface: baseSurface,
                    timelineTime: time,
                    musicTime: musicTime
                )

                canvas.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            palette.liquidTop,
                            palette.liquidMid,
                            palette.liquidBottom
                        ]),
                        startPoint: CGPoint(x: 0, y: baseSurface),
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )
            }
        }
    }

    private func honeyPath(size: CGSize, baseSurface: CGFloat, timelineTime: TimeInterval, musicTime: Double) -> Path {
        var path = Path()
        let amplitude1: CGFloat = 7
        let amplitude2: CGFloat = 4

        path.move(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: baseSurface))

        let step: CGFloat = 5
        var x: CGFloat = 0
        while x <= size.width {
            let p1 = sin((Double(x) * 0.018) + timelineTime * 2.0)
            let p2 = sin((Double(x) * 0.042) + timelineTime * 1.24)
            let motion = CGFloat(p1) * amplitude1 + CGFloat(p2) * amplitude2
            let impacts = rippleOffset(at: x, width: size.width, musicTime: musicTime)
            let y = baseSurface + motion + impacts
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }

    private func rippleOffset(at x: CGFloat, width: CGFloat, musicTime: Double) -> CGFloat {
        guard laneCount > 0 else { return 0 }
        var total: Double = 0

        for ripple in ripples {
            let age = musicTime - ripple.createdTime
            if age < 0 || age > 1.35 { continue }

            let laneProgress = (Double(ripple.lane) + 0.5) / Double(laneCount)
            let centerX = width * CGFloat(laneProgress)
            let distance = abs(x - centerX)
            let spread = max(30, width * 0.18)
            let influence = exp(-Double(distance / spread))
            let decay = exp(-age * 2.1)
            let wave = sin(age * 18.0 - Double(distance) * 0.055)

            total += wave * influence * decay * ripple.strength * 14.0
        }

        return CGFloat(total)
    }
}
