// VortexStarburstView.swift


import SwiftUI
import Vortex

// MARK: - Public entry (use in ContentView)
// Replace commented SpriteKit / RealityKit blocks with:
//
//   VortexStarburstView()
//       .ignoresSafeArea()
//
struct VortexStarburstView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Same deep navy as FireworkScene.backgroundColor & Starburst SwiftUI background
                Color(red: 0.035, green: 0.035, blue: 0.075)
                    .ignoresSafeArea()

                VortexStarburstContent(containerSize: geo.size)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
        .background(Color(red: 0.035, green: 0.035, blue: 0.075))
    }
}

// MARK: - Internal content driven by TimelineView

private struct VortexStarburstContent: View {
    var containerSize: CGSize

    // Vortex systems — configured to burst-synced emission so that each
    // particle's age ≈ global cycle time (mirrors StarburstController behaviour
    // where all 2500 particles share one globalRadiusScale).
    @State private var mainSystem: VortexSystem = Self.makeMainSystem()
    @State private var bgSystem: VortexSystem = Self.makeBGSystem()

    // Timeline reference for core overlays (halo / glow / dot) which are
    // driven with the *exact* same phase math as StarburstController.updateScene
    // and FireworkScene.updateScene.
    private let cycleDuration: Double = 7.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            // Derive cycle time from wall clock so Vortex particle age and
            // overlay phase stay in lockstep (Vortex also uses Date internally).
            let ct = now.truncatingRemainder(dividingBy: cycleDuration)

            ZStack {
                // ── BG faint streaks (550) ──────────────────────────────────
                // Very low opacity white, long thin capsules. Rendered behind main burst.
                VortexView(bgSystem) {
                    Capsule()
                        .fill(.white)
                        .frame(width: 2.2, height: 28)
                        .tag("bg")
                }
                .opacity(bgOpacity(for: ct))
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

                // ── Main starburst streaks (2500) ───────────────────────────
                // Capsule stretched along velocity (stretchFactor) so radial
                // motion automatically orients particles angle + pi/2, matching
                // FireworkScene: node.zRotation = angle + pi/2
                VortexView(mainSystem) {
                    Capsule()
                        .fill(.white)
                        .frame(width: 3.2, height: 22)
                        .tag("streak")

                    // Secondary tiny dot to add front-bright depth cue
                    // (Vortex will randomly pick between tags; mostly streaks).
                    Circle()
                        .fill(.white)
                        .frame(width: 4, height: 4)
                        .tag("dot")
                }
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

                // ── Core overlays (halo / glow / dot) ───────────────────────
                // Kept as SwiftUI rather than Vortex so we can precisely match
                // StarburstController coreHalo / centerGlow / coreDot timing.
                CoreOverlay(ct: ct)
            }
        }
    }

    // MARK: Opacity helper for BG

    private func bgOpacity(for ct: Double) -> Double {
        // Mirrors StarburstController.updateBGStreaksAlpha
        let buildEnd: Double = 0.45
        let expandEnd: Double = 4.25
        let collapseEnd: Double = 6.70
        var bgAlpha: Double = 1.0
        if ct >= buildEnd && ct < expandEnd {
            let p = (ct - buildEnd) / (expandEnd - buildEnd)
            if p > 0.30 && p < 0.88 {
                bgAlpha = lerp(1.0, 0.42, easeOutQuad((p - 0.30) / 0.58))
            } else if p >= 0.88 {
                bgAlpha = lerp(0.42, 0.88, (p - 0.88) / 0.12)
            }
        } else if ct >= expandEnd && ct < collapseEnd {
            let p = (ct - expandEnd) / (collapseEnd - expandEnd)
            bgAlpha = 0.88 + 0.12 * p
        }
        // Vortex bg particles themselves are ~0.032 alpha; multiply by bgAlpha for phase fade
        return bgAlpha
    }

    // MARK: Vortex system factories

    /// BG system — 550 faint radial streaks, same geometry as FireworkScene.setupBGStreaks.
    /// Uses emissionDuration/idleDuration to create a synchronized burst every 7.2s.
    static func makeBGSystem() -> VortexSystem {
        // birthRate * emissionDuration ≈ 550
        // 3200 * 0.17 ≈ 544
        VortexSystem(
            tags: ["bg"],
            position: [0.5, 0.5],
            shape: .point,
            birthRate: 3_200,
            emissionDuration: 0.17,
            idleDuration: 7.03, // 7.2 - 0.17
            lifespan: 6.9,
            lifespanVariation: 0.25,
            speed: 0.22,
            speedVariation: 0.16,
            angleRange: .degrees(360),
            // light damping so bg streaks drift outward gently then linger
            dampingFactor: 0.6,
            // faint white with low opacity; Vortex tints the white capsule
            colors: .single(.white.opacity(0.09)),
            size: 0.55,
            sizeVariation: 0.45,
            sizeMultiplierAtDeath: 0.85,
            stretchFactor: 6.0
        )
    }

    /// Main system — 2500 streaks radial, mimicking FireworkScene.setupParticles
    /// distribution and StarburstController collapse jitter / perspective.
    static func makeMainSystem() -> VortexSystem {
        // Colors: exact palette from FireworkScene.updateScene
        // yellow -> pale -> warm -> white -> lav -> purple -> deep -> blue
        // Vortex interpolates by lifeProgress (age/lifespan) which, because we
        // emit as a burst, maps closely to global ct.
        let ramp: [VortexSystem.Color] = [
            // pre/build (0-0.45s) — blue to yellow kept minimal; ramp starts at yellow for burst visibility
            VortexSystem.Color(red: 0.996, green: 0.855, blue: 0.169, opacity: 1.0), // colYellow
            VortexSystem.Color(red: 0.973, green: 0.941, blue: 0.612, opacity: 1.0), // colPale
            VortexSystem.Color(red: 0.98,  green: 0.96,  blue: 0.835, opacity: 1.0), // colWarm
            VortexSystem.Color(red: 1.0,   green: 1.0,   blue: 1.0,   opacity: 1.0), // colWhite (expand peak)
            VortexSystem.Color(red: 1.0,   green: 1.0,   blue: 1.0,   opacity: 1.0), // hold duplicate to create flat white plateau
            VortexSystem.Color(red: 0.72,  green: 0.71,  blue: 1.0,   opacity: 1.0), // colLav
            VortexSystem.Color(red: 0.424, green: 0.376, blue: 0.98,  opacity: 1.0), // colPurple
            VortexSystem.Color(red: 0.286, green: 0.251, blue: 0.902, opacity: 1.0), // colDeep
            VortexSystem.Color(red: 0.31,  green: 0.33,  blue: 0.99,  opacity: 1.0), // colBlue (collapse end / gap)
        ]

        // birthRate * emissionDuration ≈ 2500
        // 14_000 * 0.18 ≈ 2520
        // lifespan ~6.85 covers expand(3.9) + hold(0.25) + collapse(2.25) before gap fade
        return VortexSystem(
            tags: ["streak", "dot"],
            position: [0.5, 0.5],
            shape: .point,
            birthRate: 14_000,
            emissionDuration: 0.18,
            idleDuration: 7.02, // 7.2 - 0.18 => loop exactly cycleDuration
            lifespan: 6.85,
            lifespanVariation: 0.22,
            // Speed: unit space 1 == screen width per second.
            // maxRadius ≈ 0.32*minDim; to reach edge in ~3.9s needs ~0.08.
            // Variation 0.22 replicates inner 30% vs outer 70% rFactor distribution
            // (inner core vs outer biased pow(...,0.95)).
            speed: 0.14,
            speedVariation: 0.13,
            angleRange: .degrees(360),
            // Damping slows particles as they approach max radius (mirrors easeOutQuart).
            // Collapse is driven by lifespan ending + size shrink; Vortex has no
            // built-in inward acceleration, but damping + stretch gives similar
            // decelerating-then-fade silhouette. Attraction is added dynamically
            // via TimelineView if needed (not required for static ramp).
            dampingFactor: 1.25,
            // Slight spin for liveliness; original adds perspective via clampedZ
            angularSpeedVariation: [0, 0, 1.2],
            colors: .ramp(ramp),
            // Size: Vortex multiplies by particle's view frame. Capsule 22pt @ size 1.
            // sizeVariation replicates baseWid/baseLen jitter (1.5...2.6 / 13...22)
            // and perspectiveScale 0.6...1.4.  Front particles appear 40% larger.
            size: 0.42,
            sizeVariation: 0.55,
            // Shrink to point near max radius (original globalLengthScale 2.35 -> 0.18,
            // globalWidthScale 1.75 -> 0.45). Use 0.28 to keep visible core until collapse.
            sizeMultiplierAtDeath: 0.28,
            stretchFactor: 7.0
        )
    }

    // MARK: easing helpers (mirrors StarburstController)

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    private func easeOutQuad(_ t: Double) -> Double { 1 - (1 - t) * (1 - t) }
}

// MARK: - Core overlay (halo / glow / dot)

/// SwiftUI replica of FireworkScene coreHalo / centerGlow / coreDot.
/// Uses the *identical* phase breakpoints as StarburstController.updateScene:
/// preEnd 0.20, buildEnd 0.45, expandEnd 4.35, holdEnd 4.60, collapseEnd 6.85
private struct CoreOverlay: View {
    var ct: Double

    var body: some View {
        let phase = Self.corePhase(for: ct)
        ZStack {
            // Large soft halo (110pt glow texture in SpriteKit → 90-140pt circle)
            Circle()
                .fill(Color(red: 0.30, green: 0.38, blue: 1.0).opacity(phase.haloAlpha))
                .frame(width: phase.haloSize, height: phase.haloSize)
                .blur(radius: 18)
                .opacity(phase.haloAlpha > 0.01 ? 1 : 0)

            // Inner white glow (80pt glow texture)
            Circle()
                .fill(Color.white.opacity(phase.glowAlpha))
                .frame(width: phase.glowSize, height: phase.glowSize)
                .blur(radius: 14)
                .opacity(phase.glowAlpha > 0.01 ? 1 : 0)

            // Small yellow center dot
            Circle()
                .fill(Color(red: 1.0, green: 0.88, blue: 0.15).opacity(phase.dotAlpha))
                .frame(width: phase.dotSize, height: phase.dotSize)
                .blur(radius: 1.5)
                .opacity(phase.dotAlpha > 0.01 && !phase.dotHidden ? 1 : 0)
        }
        // Additive blend like SKBlendMode.add
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    struct Phase {
        var haloAlpha: Double; var haloSize: CGFloat
        var glowAlpha: Double; var glowSize: CGFloat
        var dotAlpha: Double; var dotSize: CGFloat; var dotHidden: Bool
    }

    static func corePhase(for ct: Double) -> Phase {
        let preEnd: Double = 0.20
        let buildEnd: Double = 0.45
        let expandEnd: Double = 4.35
        let holdEnd: Double = 4.60
        let collapseEnd: Double = 6.85
        let cycleDuration: Double = 7.2

        var haloAlpha: Double = 0, haloSize: CGFloat = 110
        var glowAlpha: Double = 0, glowSize: CGFloat = 80
        var dotAlpha: Double = 0, dotSize: CGFloat = 18
        var dotHidden = true

        if ct < preEnd {
            let p = ct / preEnd
            haloAlpha = p * 0.45
            haloSize = 110 + CGFloat(p * 40)
            glowAlpha = 0
            dotHidden = true
        } else if ct < buildEnd {
            let p = (ct - preEnd) / (buildEnd - preEnd)
            haloAlpha = 0.45 + p * 0.35
            haloSize = 150 + CGFloat(p * 30)
            glowAlpha = p * 0.35
            glowSize = 80 + CGFloat(p * 30)
            dotHidden = false
            dotAlpha = p
            dotSize = CGFloat(10 + p * 8)
        } else if ct < expandEnd {
            let p = (ct - buildEnd) / (expandEnd - buildEnd)
            let eased = easeOutQuart(p)
            let coreFade = 1 - eased * 0.85
            haloAlpha = coreFade * 0.8
            haloSize = 110 + CGFloat(coreFade * 12)
            glowAlpha = coreFade * 0.25
            glowSize = 80 + CGFloat(coreFade * 8)
            dotAlpha = max(0, 1 - p * 3.0)
            dotHidden = p > 0.35
            dotSize = 18
        } else if ct < holdEnd {
            haloAlpha = 0.12
            haloSize = 112
            glowAlpha = 0.0375
            glowSize = 90
            dotHidden = true
        } else if ct < collapseEnd {
            let p = (ct - holdEnd) / (collapseEnd - holdEnd)
            let eased = easeInCubic(p)
            haloAlpha = lerp(0.12, 0.42, eased)
            haloSize = CGFloat(lerp(112, 110, eased))
            glowAlpha = lerp(0.0375, 0.14, eased)
            glowSize = CGFloat(lerp(90, 100, eased))
            dotHidden = p <= 0.88
            if p > 0.88 { dotAlpha = (p - 0.88) / 0.12; dotSize = 14 } else { dotAlpha = 0 }
        } else {
            let gapP = (ct - collapseEnd) / (cycleDuration - collapseEnd)
            haloAlpha = 0
            glowAlpha = 0
            dotHidden = false
            dotAlpha = 0 // keep faint cluster; particles visible until gap
            _ = gapP
            dotSize = 12
        }
        return Phase(haloAlpha: haloAlpha, haloSize: haloSize,
                     glowAlpha: glowAlpha, glowSize: glowSize,
                     dotAlpha: dotAlpha, dotSize: dotSize, dotHidden: dotHidden)
    }

    // Easing duplicates of FireworkScene helpers
    @inline(__always) static func easeOutQuart(_ t: Double) -> Double {
        let p = t - 1; return 1 - p * p * p * p
    }
    @inline(__always) static func easeInCubic(_ t: Double) -> Double { t*t*t }
    @inline(__always) static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
}

// MARK: - Preview

#Preview {
    VortexStarburstView()
}
