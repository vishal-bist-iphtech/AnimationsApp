// Starburst.swift

import SwiftUI
import RealityKit
import UIKit

// MARK: - Starburst View (RealityKit)
struct StarburstView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {

                Color(red: 0.035, green: 0.035, blue: 0.075)
                    .ignoresSafeArea()

                StarburstRealityView(containerSize: geometry.size)
                    .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - RealityKit Container
private struct StarburstRealityView: View {
    var containerSize: CGSize

    @State private var controller: StarburstController?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60)) { timeline in
            RealityView { content in
                // Called once - create controller on first make
                if controller == nil {
                    let ctrl = StarburstController(containerSize: containerSize)
                    ctrl.setup()
                    content.add(ctrl.root)
                    // capture for updates on next frame via Task
                    Task { @MainActor in
                        self.controller = ctrl
                    }
                }
            } update: { content in
                guard let ctrl = controller else { return }
                let now = timeline.date.timeIntervalSinceReferenceDate
                ctrl.update(at: now, containerSize: containerSize)
            }
        }
        .onChange(of: containerSize) { _, newSize in
            controller?.updateContainerSize(newSize)
        }
    }
}

// MARK: - Controller (mirrors FireworkScene)
@MainActor
private final class StarburstController {
    let root = Entity()
    private var containerSize: CGSize
    private var maxRadiusPoints: CGFloat = 130
    private var centerOffset: SIMD3<Float> = .zero

    // Config (same as FireworkScene)
    private let particleCount = 2500
    private let bgStreakCount = 550
    private let cycleDuration: TimeInterval = 7.2
    private var startTime: TimeInterval = CACurrentMediaTime()
    private var particles: [Particle] = []
    private var particleEntities: [ModelEntity] = []
    private var bgEntities: [ModelEntity] = []

    private var coreHalo: ModelEntity?
    private var coreDot: ModelEntity?
    private var centerGlow: ModelEntity?

    private let numberOfZDepths = 5

    // Shared meshes — sphere stretched to capsule/water-droplet (vs rectangle), box for bg
    private let particleMesh = MeshResource.generateSphere(radius: 0.5)
    private let bgMesh = MeshResource.generateBox(size: 1.0)
    private let sphereMesh = MeshResource.generateSphere(radius: 0.5)

    struct Particle {
        var angle: CGFloat
        var targetRPoints: CGFloat
        var baseLenPoints: CGFloat
        var baseWidPoints: CGFloat
        var zDepth: CGFloat
        var zVelocity: CGFloat
        var collapseJitter: CGFloat // per-particle variance to avoid whole-canvas scaling
        var endScale: CGFloat // per-particle final radius (avoid single point)
        var entity: ModelEntity
    }

    init(containerSize: CGSize) {
        self.containerSize = containerSize
        updateMaxRadius()
    }

    func updateContainerSize(_ size: CGSize) {
        containerSize = size
        updateMaxRadius()
    }

    private func updateMaxRadius() {
        let minDim = min(containerSize.width, containerSize.height)
        // Just a little bigger (was 0.44) — increase ~5% radius
        var r = minDim * 0.46
        r = max(190, min(r, 440))
        maxRadiusPoints = r
    }

    func setup() {
        // Root already added; configure camera if needed (use default camera)
        // Add vignette? Keep simple — background color handled by SwiftUI
        setupCore()
        setupBGStreaks()
        setupParticles()
    }

    private func setupCore() {
        // Background circles removed per request — no large halo/glow at beginning
        // Keep only small core dot (yellow) for center
        let dot = ModelEntity(mesh: sphereMesh, materials: [UnlitMaterial(color: UIColor(red: 1.0, green: 0.88, blue: 0.15, alpha: 1.0))])
        dot.scale = SIMD3<Float>(0.028, 0.028, 0.028)
        dot.position = [0,0,0.025]
        dot.isEnabled = false
        root.addChild(dot)
        coreDot = dot
        // coreHalo & centerGlow intentionally not created (previously blue background circles)
        coreHalo = nil
        centerGlow = nil
    }

    private func setupBGStreaks() {
        for _ in 0..<bgStreakCount {
            let angle = CGFloat.random(in: 0..<(2*CGFloat.pi))
            let lenFactor = CGFloat.random(in: 0.68...1.0)
            let lenPoints = maxRadiusPoints * 1.35 * lenFactor
            let widPoints: CGFloat = CGFloat.random(in: 0.6...1.15)
            // initial not visible; will be positioned at center and scaled
            var mat = UnlitMaterial(color: .white.withAlphaComponent(0.032))
            mat.blending = .transparent(opacity: .init(floatLiteral: 0.032))
            let e = ModelEntity(mesh: bgMesh, materials: [mat])
            // Store angle in entity transform for later? We'll recompute each frame from stored Particle-like data
            // Instead store angle/len in entity's name or userData — simpler store in separate arrays
            e.name = "\(angle),\(lenPoints),\(widPoints)"
            // initial transform at center, will be updated in update loop
            e.position = [0,0,-0.02]
            // scale to length/width (meters): 1 point = 0.00185 m (just a little bigger)
            let wM = Float(widPoints * 0.00185)
            let hM = Float(lenPoints * 0.00185)
            e.scale = SIMD3<Float>(wM, hM, wM)
            // rotation will be set each frame (or now)
            e.orientation = simd_quatf(angle: Float(angle - .pi/2), axis: [0,0,1])
            e.isEnabled = true
            root.addChild(e)
            bgEntities.append(e)
        }
    }

    private func setupParticles() {
        particles.reserveCapacity(particleCount)
        for i in 0..<particleCount {
            let angle = CGFloat.random(in: 0..<(2*CGFloat.pi))

            // Center not vacant — 30% inner uniform, 70% outer
            let rFactor: CGFloat
            if i < Int(CGFloat(particleCount) * 0.30) {
                rFactor = CGFloat.random(in: 0.02...0.32)
            } else {
                let rRand = CGFloat.random(in: 0...1)
                let biased = pow(rRand, 0.95)
                rFactor = 0.22 + biased * 0.78
            }
            let targetR = maxRadiusPoints * rFactor
            let baseLen = CGFloat.random(in: 13...22) * (0.9 + 0.2 * rFactor)
            let baseWid = CGFloat.random(in: 1.5...2.6) * (rFactor > 0.85 ? 1.08 : 1.0)
            let zDepth = CGFloat.random(in: -1.0...1.0)
            let zVelocity = CGFloat.random(in: -0.45...0.45)
            let collapseJitter = CGFloat.random(in: -0.07...0.07)
            let endScale = CGFloat.random(in: 0.07...0.18) // avoid single point collapse

            var mat = UnlitMaterial(color: .white.withAlphaComponent(0))
            mat.blending = .transparent(opacity: .init(floatLiteral: 0))
            let entity = ModelEntity(mesh: particleMesh, materials: [mat])
            entity.position = [0,0,0]
            entity.orientation = simd_quatf(angle: Float(angle + .pi/2), axis: [0,0,1])
            entity.isEnabled = false
            // initial small scale — 0.00185 m/point (just a little bigger) + capsule shape
            entity.scale = SIMD3<Float>(Float(baseWid*0.00185), Float(baseLen*0.00185), 1)

            // Depth layer z offset not needed as separate entities, just z position
            root.addChild(entity)
            particleEntities.append(entity)
            particles.append(Particle(angle: angle, targetRPoints: targetR, baseLenPoints: baseLen, baseWidPoints: baseWid, zDepth: zDepth, zVelocity: zVelocity, collapseJitter: collapseJitter, endScale: endScale, entity: entity))
        }
    }

    // MARK: - Easing
    @inline(__always) private func easeOutCubic(_ t: CGFloat) -> CGFloat { let p=t-1; return p*p*p+1 }
    @inline(__always) private func easeOutQuart(_ t: CGFloat) -> CGFloat { let p=t-1; return 1 - p*p*p*p } // slower at end
    @inline(__always) private func easeInCubic(_ t: CGFloat) -> CGFloat { t*t*t }
    @inline(__always) private func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        if t<0.5 { return 4*t*t*t }
        let p=2*t-2; return 0.5*p*p*p+1
    }
    @inline(__always) private func easeOutQuad(_ t: CGFloat) -> CGFloat { 1-(1-t)*(1-t) }
    @inline(__always) private func lerp(_ a:CGFloat,_ b:CGFloat,_ t:CGFloat)->CGFloat { a+(b-a)*t }
    private func lerpColor(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        var ar:CGFloat=0,ag:CGFloat=0,ab:CGFloat=0,aa:CGFloat=0
        var br:CGFloat=0,bg:CGFloat=0,bb:CGFloat=0,ba:CGFloat=0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return UIColor(red: lerp(ar,br,t), green: lerp(ag,bg,t), blue: lerp(ab,bb,t), alpha: lerp(aa,ba,t))
    }

    func update(at now: TimeInterval, containerSize: CGSize) {
        // Handle first call
        if startTime == 0 { startTime = now }
        let elapsed = now - startTime
        let t = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        updateScene(for: CGFloat(t))
        updateBGStreaksAlpha(for: CGFloat(t))
    }

    private func updateScene(for ct: CGFloat) {
        let preEnd: CGFloat = 0.20
        let buildEnd: CGFloat = 0.45
        let expandEnd: CGFloat = 4.35 // expand a bit longer + slower
        let holdEnd: CGFloat = 4.60 // stationary at max (no velocity)
        let collapseEnd: CGFloat = 6.85

        var globalRadiusScale: CGFloat = 0
        var globalColor: UIColor = .white
        var globalAlpha: CGFloat = 1
        var globalLengthScale: CGFloat = 1
        var globalWidthScale: CGFloat = 1
        var particlesHidden = false
        var zSpread: CGFloat = 0

        let colYellow = UIColor(red: 0.996, green: 0.855, blue: 0.169, alpha: 1)
        let colPale = UIColor(red: 0.973, green: 0.941, blue: 0.612, alpha: 1)
        let colWarm = UIColor(red: 0.98, green: 0.96, blue: 0.835, alpha: 1)
        let colWhite = UIColor.white
        let colLav = UIColor(red: 0.72, green: 0.71, blue: 1.0, alpha: 1)
        let colPurple = UIColor(red: 0.424, green: 0.376, blue: 0.98, alpha: 1)
        let colDeep = UIColor(red: 0.286, green: 0.251, blue: 0.902, alpha: 1)
        let colBlue = UIColor(red: 0.31, green: 0.33, blue: 0.99, alpha: 1)

        // Core defaults
        var haloAlpha: CGFloat = 0, haloScale: Float = 0.18, glowAlpha: CGFloat = 0, glowScale: Float = 0.12
        var dotVisible = false, dotAlpha: CGFloat = 0, dotScale: Float = 0.018

        if ct < preEnd {
            let p = ct / preEnd
            globalRadiusScale = 0.04 * p
            globalColor = colBlue
            globalAlpha = p * 0.45
            globalLengthScale = 0.55
            globalWidthScale = 0.9
            particlesHidden = p < 0.08
            haloAlpha = p * 0.45
            haloScale = Float(0.18 + Double(p)*0.04)
        } else if ct < buildEnd {
            let p = (ct - preEnd) / (buildEnd - preEnd)
            globalRadiusScale = 0.04 + 0.06 * p
            globalColor = colYellow
            globalAlpha = 0.45 + p * 0.55
            globalLengthScale = 0.55 + p * 0.45
            globalWidthScale = 0.9 + p * 0.35
            zSpread = p * 0.15
            haloAlpha = 0.45 + p * 0.35
            haloScale = Float(0.18 + Double(p)*0.03)
            glowAlpha = p * 0.35
            glowScale = Float(0.12 + Double(p)*0.02)
            dotVisible = true
            dotAlpha = p
            dotScale = Float(0.012 + Double(p)*0.006)
        } else if ct < expandEnd {
            let p = (ct - buildEnd) / (expandEnd - buildEnd)
            let eased = easeOutQuart(p) // slower as approaches max (was easeOutCubic)
            globalRadiusScale = 0.10 + 0.90 * eased
            zSpread = sin(Double(p) * .pi) * 0.9
            if p < 0.30 {
                let cp = p / 0.30
                if cp < 0.5 { globalColor = lerpColor(colYellow, colPale, cp*2) }
                else { globalColor = lerpColor(colPale, colWarm, (cp-0.5)*2) }
            } else if p < 0.45 {
                globalColor = lerpColor(colWarm, colWhite, (p-0.30)/0.15)
            } else { globalColor = colWhite }
            globalLengthScale = lerp(2.35, 0.18, eased)
            globalWidthScale = lerp(1.75, 0.45, eased)
            globalAlpha = 1.0 - p * 0.08
            let coreFade = 1 - eased * 0.85
            haloAlpha = coreFade * 0.8
            haloScale = Float(0.18 + Double(coreFade)*0.05)
            glowAlpha = coreFade * 0.25
            dotVisible = p <= 0.35
            dotAlpha = max(0, 1 - p*3.0)
            dotScale = 0.018
        } else if ct < holdEnd {
            // Stationary at max expansion — velocity zero (no flicker)
            globalRadiusScale = 1.0
            globalColor = colWhite
            globalLengthScale = 0.18 // point stationary
            globalWidthScale = 0.45
            globalAlpha = 0.92
            zSpread = 0
            haloAlpha = 0.12
            haloScale = 0.1875
            glowAlpha = 0.0375
            glowScale = 0.09
            dotVisible = false
        } else if ct < collapseEnd {
            let p = (ct - holdEnd) / (collapseEnd - holdEnd)
            let eased = easeInCubic(p) // accelerating inward (slow→fast)
            // Per-particle handled later, but set global reference for non-particle elements
            globalRadiusScale = 1.0 // placeholder (per-particle overrides)
            zSpread = sin(Double(p) * .pi) * 0.6 // smaller spread, 0 at both ends
            if p < 0.38 { globalColor = lerpColor(colWhite, colLav, p/0.38) }
            else if p < 0.62 { globalColor = lerpColor(colLav, colPurple, (p-0.38)/0.24) }
            else if p < 0.85 { globalColor = lerpColor(colPurple, colDeep, (p-0.62)/0.23) }
            else { globalColor = lerpColor(colDeep, colBlue, (p-0.85)/0.15) }
            // Reverse of expansion: point (0.18) → droplet (2.35) as acceleration increases
            globalLengthScale = lerp(0.18, 2.35, eased)
            globalWidthScale = lerp(0.45, 1.75, eased)
            globalAlpha = 0.92 - p * 0.18 // fade slightly while contracting, keep visible until center
            haloAlpha = lerp(0.12, 0.42, eased)
            haloScale = Float(lerp(0.1875, 0.16, Double(eased)))
            glowAlpha = lerp(0.0375, 0.14, eased)
            glowScale = Float(lerp(0.09, 0.10, Double(eased)))
            dotVisible = false // center stays filled by particles until all back, no dot yet
            dotAlpha = 0
        } else {
            // Gap before restart — keep center filled (particles at endScale cluster) until last moment
            // Don't clear center as long as particles are back; vanish/restart just before next cycle
            let gapP = (ct - collapseEnd) / CGFloat(cycleDuration - collapseEnd) // 0..1 (0.35s gap)
            globalRadiusScale = 0.12 // small cluster, not single point
            globalColor = colBlue
            globalLengthScale = 0.22
            globalWidthScale = 0.5
            globalAlpha = 0.70 * (1 - gapP) // fade while still at center
            particlesHidden = gapP > 0.85 // hide only last 15% (~0.05s) before restart — center not cleared early
            haloAlpha = 0
            glowAlpha = 0
            haloAlpha = 0.12
            glowAlpha = 0.05
            dotVisible = true
            dotAlpha = 0.0
        }

        // Update core
        if let halo = coreHalo {
            halo.isEnabled = haloAlpha > 0.01
            halo.scale = SIMD3<Float>(repeating: haloScale)
            if var mat = halo.model?.materials.first as? UnlitMaterial {
                // lerp color handled above for collapse
                var c = UIColor(red: 0.30, green: 0.38, blue: 1.0, alpha: haloAlpha)
                if ct >= expandEnd && ct < collapseEnd {
                    let p = (ct - expandEnd)/(collapseEnd - expandEnd)
                    c = lerpColor(colWhite, colBlue, p).withAlphaComponent(haloAlpha)
                }
                mat.color = .init(tint: c)
                mat.blending = .transparent(opacity: .init(floatLiteral: Float(haloAlpha)))
                halo.model?.materials = [mat]
            }
        }
        if let glow = centerGlow {
            glow.isEnabled = glowAlpha > 0.01
            glow.scale = SIMD3<Float>(repeating: glowScale)
            if var mat = glow.model?.materials.first as? UnlitMaterial {
                mat.color = .init(tint: UIColor(white: 1, alpha: glowAlpha))
                mat.blending = .transparent(opacity: .init(floatLiteral: Float(glowAlpha)))
                glow.model?.materials = [mat]
            }
            glow.isEnabled = glowAlpha > 0.01
        }
        if let dot = coreDot {
            dot.isEnabled = dotVisible && dotAlpha > 0.001
            dot.scale = SIMD3<Float>(repeating: dotScale)
            if var mat = dot.model?.materials.first as? UnlitMaterial {
                mat.color = .init(tint: UIColor(red: 1.0, green: 0.88, blue: 0.15, alpha: dotAlpha))
                mat.blending = .transparent(opacity: .init(floatLiteral: Float(dotAlpha)))
                dot.model?.materials = [mat]
            }
        }

        if particlesHidden {
            for e in particleEntities { e.isEnabled = false }
            return
        }

        // Particle update — per-particle collapse (particles individually fall, not canvas) + hold stationary
        let isCollapseOrGap = ct >= holdEnd
        let collapseP: CGFloat = ct < holdEnd ? 0 : ct < collapseEnd ? (ct - holdEnd) / (collapseEnd - holdEnd) : 1
        for idx in particles.indices {
            let pr = particles[idx]
            let e = particleEntities[idx]
            e.isEnabled = true

            let effectiveZ = pr.zDepth + zSpread * pr.zVelocity
            let clampedZ = max(-1, min(1, effectiveZ))
            let perspectiveScale = 1.0 + clampedZ * 0.40

            // Use per-particle radius during collapse/gap to avoid whole-canvas sinking
            // Delay per particle so they don't all move together — center stays filled until last arrives
            let baseR: CGFloat
            var curLenScale = globalLengthScale
            var curWidScale = globalWidthScale
            if isCollapseOrGap {
                let delay = (pr.collapseJitter + 0.07) / 0.14 * 0.22 // 0...0.22 staggered start
                let pAdj = collapseP < delay ? 0 : (collapseP - delay) / (1 - delay)
                let easedAdj = easeInCubic(pAdj) // slow start (point) → fast end (droplet) — reverse of expansion
                let indScale = 1.0 + (pr.endScale - 1.0) * easedAdj
                baseR = pr.targetRPoints * indScale
                // Reverse of expansion: point (0.18) → droplet (2.35) as acceleration increases
                curLenScale = lerp(0.18, 2.35, easedAdj)
                curWidScale = lerp(0.45, 1.75, easedAdj)
            } else {
                baseR = pr.targetRPoints * globalRadiusScale
                curLenScale = globalLengthScale
                curWidScale = globalWidthScale
            }
            let baseX = cos(pr.angle) * baseR
            let baseY = sin(pr.angle) * baseR
            // offset then perspective — 0.00185 m/point (just a little bigger)
            let sx = Float(baseX * 0.00185 * perspectiveScale)
            let sy = Float(baseY * 0.00185 * perspectiveScale)
            let sz = Float(clampedZ * 0.08)
            e.position = SIMD3<Float>(sx, sy, sz)
            e.orientation = simd_quatf(angle: Float(pr.angle + .pi/2), axis: [0,0,1])

            let sizeScale = Float(perspectiveScale)
            let hPoints = pr.baseLenPoints * curLenScale * CGFloat(sizeScale)
            let wPoints = pr.baseWidPoints * curWidScale * CGFloat(sizeScale)
            let hM = max(1.8, hPoints) * 0.00185
            let wM = max(1.1, wPoints) * 0.00185
            e.scale = SIMD3<Float>(Float(wM), Float(hM), Float(wM))

            // color + alpha
            let depthAlpha = 0.62 + (clampedZ + 1)/2 * 0.38
            let a = globalAlpha * depthAlpha
            let col = globalColor.withAlphaComponent(a)
            if var mat = e.model?.materials.first as? UnlitMaterial {
                mat.color = .init(tint: col)
                mat.blending = .transparent(opacity: .init(floatLiteral: Float(a)))
                e.model?.materials = [mat]
            }
        }
    }

    private func updateBGStreaksAlpha(for ct: CGFloat) {
        let buildEnd: CGFloat = 0.45
        let expandEnd: CGFloat = 4.25
        let collapseEnd: CGFloat = 6.70
        var bgAlpha: CGFloat = 1
        if ct >= buildEnd && ct < expandEnd {
            let p = (ct - buildEnd)/(expandEnd - buildEnd)
            if p > 0.30 && p < 0.88 { bgAlpha = lerp(1.0, 0.42, easeOutQuad((p-0.30)/0.58)) }
            else if p >= 0.88 { bgAlpha = lerp(0.42, 0.88, (p-0.88)/0.12) }
        } else if ct >= expandEnd && ct < collapseEnd {
            let p = (ct - expandEnd)/(collapseEnd - expandEnd)
            bgAlpha = 0.88 + 0.12 * p
        }
        for e in bgEntities {
            if var mat = e.model?.materials.first as? UnlitMaterial {
                // bg faint white
                let a = 0.032 * Double(bgAlpha)
                mat.color = .init(tint: UIColor(white: 1, alpha: CGFloat(a)))
                mat.blending = .transparent(opacity: .init(floatLiteral: Float(a)))
                e.model?.materials = [mat]
            }
        }
    }
}

#Preview {
    StarburstView()
}
