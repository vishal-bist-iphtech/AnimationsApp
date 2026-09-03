import SpriteKit
import UIKit

final class FireworkScene: SKScene {

    // MARK: - Config
    private let particleCount = 2500
    private var maxRadius: CGFloat = 0
    private var centerPoint: CGPoint = .zero
    private let cycleDuration: TimeInterval = 7.2
    private var startTime: TimeInterval = 0
    private var lastTime: TimeInterval = 0
    
    // 3D Configuration
    private let numberOfZDepths = 5
    private var perspectiveStrength: CGFloat = 0.35

    // Textures
    private var streakTexture: SKTexture!
    private var glowTexture: SKTexture!

    // Nodes
    private var particleContainer: SKNode!
    private var bgStreaksNode: SKNode!
    private var coreHalo: SKSpriteNode!
    private var coreDot: SKShapeNode!
    private var centerGlow: SKSpriteNode!
    private var vignetteNode: SKSpriteNode!
    
    // Depth layer nodes
    private var depthLayers: [SKNode] = []

    // Particle data
    private struct Particle {
        var angle: CGFloat
        var targetR: CGFloat
        var baseLen: CGFloat
        var baseWid: CGFloat
        var node: SKSpriteNode
        var zDepth: CGFloat // -1 (back) to 1 (front)
        var zVelocity: CGFloat
    }
    private var particles: [Particle] = []

    // MARK: - Init
    override init(size: CGSize) {
        streakTexture = Self.makeStreakTexture()
        glowTexture = Self.makeGlowTexture(diameter: 256)
        super.init(size: size)
        backgroundColor = UIColor(red: 0.035, green: 0.035, blue: 0.075, alpha: 1)
        scaleMode = .resizeFill
        streakTexture.filteringMode = .linear
        glowTexture.filteringMode = .linear
    }

    required init?(coder aDecoder: NSCoder) {
        streakTexture = Self.makeStreakTexture()
        glowTexture = Self.makeGlowTexture(diameter: 256)
        super.init(coder: aDecoder)
    }

    // MARK: - Texture factories
    private static func makeStreakTexture() -> SKTexture {
        let h: CGFloat = 28
        let w: CGFloat = 4
        let size = CGSize(width: w, height: h)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: size))
            let colors: [CGColor] = [
                UIColor.white.cgColor,
                UIColor.white.withAlphaComponent(0.95).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor
            ]
            let locations: [CGFloat] = [0.0, 0.32, 1.0]
            guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations) else { return }
            cg.drawLinearGradient(grad, start: CGPoint(x: w/2, y: 0), end: CGPoint(x: w/2, y: h), options: [])
            cg.setFillColor(UIColor.white.cgColor)
            cg.fillEllipse(in: CGRect(x: 0, y: -1, width: w, height: w+2))
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .linear
        return tex
    }

    private static func makeGlowTexture(diameter: CGFloat) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.clear(CGRect(origin: .zero, size: size))
            let colors: [CGColor] = [
                UIColor.white.withAlphaComponent(1.0).cgColor,
                UIColor.white.withAlphaComponent(0.55).cgColor,
                UIColor.white.withAlphaComponent(0.15).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor
            ]
            let locs: [CGFloat] = [0.0, 0.22, 0.45, 1.0]
            guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locs) else { return }
            let center = CGPoint(x: size.width/2, y: size.height/2)
            cg.drawRadialGradient(grad, startCenter: center, startRadius: 0, endCenter: center, endRadius: diameter/2, options: .drawsAfterEndLocation)
        }
        let tex = SKTexture(image: img)
        tex.filteringMode = .linear
        return tex
    }

    // MARK: - Setup
    override func didMove(to view: SKView) {
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        updateCenterAndRadius()
        setupScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard oldSize != .zero else { return }
        updateCenterAndRadius()
        repositionNodes()
    }
    
    private func updateCenterAndRadius() {
        centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)

        let minDim = min(size.width, size.height)
        maxRadius = minDim * 0.32
        maxRadius = max(120, min(maxRadius, 360))
    }
    
    private func repositionNodes() {
        coreHalo?.position = centerPoint
        coreDot?.position = centerPoint
        centerGlow?.position = centerPoint
        vignetteNode?.position = centerPoint
        bgStreaksNode?.position = centerPoint
        particleContainer?.position = .zero
        for layer in depthLayers {
            layer.position = .zero
        }
    }

    private func setupScene() {
        setupBGLayers()
        setupBGStreaks()
        setupParticleContainer()
        setupDepthLayers()
        setupCore()
        setupParticles()
    }

    private func setupBGLayers() {
        vignetteNode = SKSpriteNode(texture: glowTexture)
        vignetteNode.size = CGSize(width: max(size.width, size.height) * 1.6, height: max(size.width, size.height) * 1.6)
        vignetteNode.position = centerPoint
        vignetteNode.color = UIColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1)
        vignetteNode.colorBlendFactor = 1
        vignetteNode.alpha = 0.55
        vignetteNode.zPosition = -1
        vignetteNode.blendMode = .alpha
        addChild(vignetteNode)
    }

    private func setupBGStreaks() {
        bgStreaksNode = SKNode()
        bgStreaksNode.position = centerPoint
        bgStreaksNode.zPosition = 0
        addChild(bgStreaksNode)

        let count = 550
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0..<(2*CGFloat.pi))
            let lenFactor = CGFloat.random(in: 0.68...1.0)
            let len = maxRadius * 1.35 * lenFactor
            let wid: CGFloat = CGFloat.random(in: 0.6...1.15)
            let path = CGMutablePath()
            let inner: CGFloat = CGFloat.random(in: 12...36)
            path.move(to: CGPoint(x: 0, y: inner))
            path.addLine(to: CGPoint(x: 0, y: len))
            let line = SKShapeNode(path: path)
            line.strokeColor = UIColor(white: 1.0, alpha: 0.032)
            line.lineWidth = wid
            line.lineCap = .round
            line.glowWidth = 0
            line.alpha = CGFloat.random(in: 0.5...1.0)
            line.blendMode = .alpha
            line.zRotation = angle - CGFloat.pi/2
            bgStreaksNode.addChild(line)
        }
        bgStreaksNode.alpha = 0.95
    }

    private func setupDepthLayers() {
        for i in 0..<numberOfZDepths {
            let layer = SKNode()
            let depthFactor = CGFloat(i) / CGFloat(numberOfZDepths - 1)
            let zPos = (depthFactor - 0.5) * 2 * -10
            layer.zPosition = zPos
            layer.position = .zero
            layer.name = "depthLayer_\(i)"
            depthLayers.append(layer)
            particleContainer.addChild(layer)
        }
    }

    private func setupParticleContainer() {
        particleContainer = SKNode()
        particleContainer.position = .zero
        particleContainer.zPosition = 2
        addChild(particleContainer)
    }

    private func setupCore() {
        coreHalo = SKSpriteNode(texture: glowTexture)
        coreHalo.size = CGSize(width: 110, height: 110)
        coreHalo.position = centerPoint
        coreHalo.zPosition = 3
        coreHalo.blendMode = .add
        coreHalo.colorBlendFactor = 1
        coreHalo.color = UIColor(red: 0.30, green: 0.38, blue: 1.0, alpha: 1)
        coreHalo.alpha = 0
        addChild(coreHalo)

        centerGlow = SKSpriteNode(texture: glowTexture)
        centerGlow.size = CGSize(width: 80, height: 80)
        centerGlow.position = centerPoint
        centerGlow.zPosition = 2.5
        centerGlow.blendMode = .add
        centerGlow.colorBlendFactor = 1
        centerGlow.color = UIColor(white: 1, alpha: 1)
        centerGlow.alpha = 0
        addChild(centerGlow)

        coreDot = SKShapeNode(circleOfRadius: 9)
        coreDot.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.15, alpha: 1)
        coreDot.strokeColor = .clear
        coreDot.position = centerPoint
        coreDot.zPosition = 4
        coreDot.isHidden = true
        coreDot.blendMode = .add
        coreDot.lineWidth = 0
        coreDot.glowWidth = 6
        addChild(coreDot)
    }

    private func setupParticles() {
        particles.reserveCapacity(particleCount)
        
        for i in 0..<particleCount {
            let angle = CGFloat.random(in: 0..<(2*CGFloat.pi))
            
            // FIX 1: Center NOT vacant — ensure dense core
            // 30% inner particles (0.02-0.32), 70% outer (0.22-1.0) with bias to fill center
            let rFactor: CGFloat
            if i < Int(CGFloat(particleCount) * 0.30) {
                // Inner core - uniform 0.02...0.32
                rFactor = CGFloat.random(in: 0.02...0.32)
            } else {
                let rRand = CGFloat.random(in: 0...1)
                // pow 1.15 biases slightly to center while still reaching outer
                let biased = pow(rRand, 0.95)
                rFactor = 0.22 + biased * 0.78 // 0.22...1.0
            }
            let targetR = maxRadius * rFactor

            // Base size: modest randomness, outer slightly longer but global scale will dominate
            let baseLen = CGFloat.random(in: 10...18) * (0.9 + 0.2 * rFactor)
            let baseWid = CGFloat.random(in: 1.0...1.9) * (rFactor > 0.85 ? 1.05 : 1.0)
            
            let zDepth = CGFloat.random(in: -1.0...1.0)
            let zVelocity = CGFloat.random(in: -0.45...0.45)

            let node = SKSpriteNode(texture: streakTexture)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.size = CGSize(width: baseWid, height: baseLen)
            node.colorBlendFactor = 1.0
            node.blendMode = .add
            node.position = centerPoint
            node.zRotation = angle + CGFloat.pi/2
            node.alpha = 0
            node.isHidden = true
            
            let normalizedZ = (zDepth + 1) / 2
            let layerIndex = Int(normalizedZ * CGFloat(numberOfZDepths - 1))
            let safeIndex = min(max(layerIndex, 0), numberOfZDepths - 1)
            depthLayers[safeIndex].addChild(node)

            particles.append(Particle(
                angle: angle,
                targetR: targetR,
                baseLen: baseLen,
                baseWid: baseWid,
                node: node,
                zDepth: zDepth,
                zVelocity: zVelocity
            ))
        }
    }

    // MARK: - Helper functions
    @inline(__always) private func easeOutCubic(_ t: CGFloat) -> CGFloat {
        let p = t - 1
        return p * p * p + 1
    }
    @inline(__always) private func easeInCubic(_ t: CGFloat) -> CGFloat {
        return t * t * t
    }
    @inline(__always) private func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        if t < 0.5 { return 4 * t * t * t }
        let p = 2 * t - 2
        return 0.5 * p * p * p + 1
    }
    @inline(__always) private func easeOutQuad(_ t: CGFloat) -> CGFloat {
        return 1 - (1 - t) * (1 - t)
    }
    @inline(__always) private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        return a + (b - a) * t
    }
    @inline(__always) private func lerpColor(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return UIColor(red: lerp(ar, br, t), green: lerp(ag, bg, t), blue: lerp(ab, bb, t), alpha: lerp(aa, ba, t))
    }

    override func update(_ currentTime: TimeInterval) {
        if lastTime == 0 {
            lastTime = currentTime
            startTime = currentTime
            return
        }
        _ = min(0.1, currentTime - lastTime)
        lastTime = currentTime

        let elapsed = currentTime - startTime
        let t = elapsed.truncatingRemainder(dividingBy: cycleDuration)
        updateScene(for: t)
    }

    private func updateScene(for t: TimeInterval) {
        let ct = CGFloat(t)

        // ----- Single smooth cycle: pre -> build -> expand -> collapse (no hold gap) -----
        let preEnd: CGFloat = 0.20
        let buildEnd: CGFloat = 0.45
        let expandEnd: CGFloat = 4.25
        let collapseEnd: CGFloat = 6.70

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

        if ct < preEnd {
            let p = ct / preEnd
            globalRadiusScale = 0.04 * p
            globalColor = colBlue
            globalAlpha = p * 0.45
            // FIX 2: max length/width at center, decreases outward
            globalLengthScale = 0.55
            globalWidthScale = 0.9
            particlesHidden = p < 0.08
            zSpread = 0
            // core halo pulse
            coreHalo.alpha = p * 0.45
            coreHalo.size = CGSize(width: 110 + p*40, height: 110 + p*40)
            centerGlow.alpha = 0
            coreDot.isHidden = true
        } else if ct < buildEnd {
            let p = (ct - preEnd) / (buildEnd - preEnd)
            globalRadiusScale = 0.04 + 0.06 * p // 0.04 -> 0.10
            globalColor = colYellow
            globalAlpha = 0.45 + p * 0.55
            globalLengthScale = 0.55 + p * 0.45 // growing but still short near core
            globalWidthScale = 0.9 + p * 0.35
            zSpread = p * 0.15
            coreHalo.alpha = 0.45 + p * 0.35
            coreHalo.size = CGSize(width: 150 + p*30, height: 150 + p*30)
            centerGlow.alpha = p * 0.35
            centerGlow.size = CGSize(width: 80 + p*30, height: 80 + p*30)
            coreDot.isHidden = false
            coreDot.alpha = p
            coreDot.setScale(0.6 + p*0.4)
        } else if ct < expandEnd {
            let p = (ct - buildEnd) / (expandEnd - buildEnd)
            let eased = easeOutCubic(p)
            // 0.10 -> 1.0 smooth single expansion
            globalRadiusScale = 0.10 + 0.90 * eased
            zSpread = sin(p * .pi) * 0.9
            
            // Color: yellow -> pale -> warm -> white in first 35% of expansion
            if p < 0.30 {
                let cp = p / 0.30
                if cp < 0.5 {
                    globalColor = lerpColor(colYellow, colPale, cp * 2)
                } else {
                    globalColor = lerpColor(colPale, colWarm, (cp - 0.5) * 2)
                }
            } else if p < 0.45 {
                let cp = (p - 0.30) / 0.15
                globalColor = lerpColor(colWarm, colWhite, cp)
            } else {
                globalColor = colWhite
            }
            
            // FIX 2: length/width MAX at beginning (near center), decreasing to point at max distance
            // eased 0->1, length 2.35 -> 0.20 (tiny point)
            globalLengthScale = lerp(2.35, 0.18, eased)
            globalWidthScale = lerp(1.75, 0.45, eased)
            globalAlpha = 1.0 - p * 0.08 // slight fade
            
            // core fades as particles take over
            let coreFade = 1 - eased * 0.85
            coreHalo.alpha = coreFade * 0.8
            centerGlow.alpha = coreFade * 0.25
            coreDot.alpha = max(0, 1 - p*3.0)
            if p > 0.35 { coreDot.isHidden = true }
            
        } else if ct < collapseEnd {
            let p = (ct - expandEnd) / (collapseEnd - expandEnd) // 0->1
            let eased = easeInCubic(p)
            // Single smooth collapse 1.0 -> 0.05 without pause
            globalRadiusScale = 1.0 + (0.05 - 1.0) * eased
            zSpread = 0.9 * (1 - p)
            
            // Color: white -> lav -> purple -> deep -> blue continuously
            if p < 0.38 {
                globalColor = lerpColor(colWhite, colLav, p / 0.38)
            } else if p < 0.62 {
                globalColor = lerpColor(colLav, colPurple, (p - 0.38)/0.24)
            } else if p < 0.85 {
                globalColor = lerpColor(colPurple, colDeep, (p - 0.62)/0.23)
            } else {
                globalColor = lerpColor(colDeep, colBlue, (p - 0.85)/0.15)
            }
            
            // During collapse, particles re-streak slightly as they accelerate inward, then shrink to core
            // Use velocity-based length: peak mid-collapse
            // 0.18 at collapse start, ~1.35 mid, ~0.42 at end
            let velPeak = sin(p * .pi) // 0->1->0
            globalLengthScale = 0.18 + velPeak * 1.15 + p * p * 0.22 // 0.18 -> 1.33 -> 0.40
            globalWidthScale = 0.45 + velPeak * 0.72 + p * 0.15  // 0.45 -> 1.17 -> 0.60
            globalAlpha = 1.0 - p * 0.22
            
            // core reforms
            let coreReappear = eased
            coreHalo.alpha = coreReappear * 0.52
            coreHalo.color = lerpColor(colWhite, colBlue, p)
            coreHalo.size = CGSize(width: lerp(30, 110, eased), height: lerp(30, 110, eased))
            centerGlow.alpha = coreReappear * 0.18
            if p > 0.88 {
                coreDot.isHidden = false
                coreDot.alpha = (p - 0.88)/0.12
            } else if p > 0.5 {
                coreDot.isHidden = true
            }
        } else {
            // tail gap before next cycle
            particlesHidden = true
            globalRadiusScale = 0.05
            coreHalo.alpha = 0.12
            centerGlow.alpha = 0.05
            coreDot.isHidden = false
            coreDot.alpha = 0.0
            zSpread = 0
        }

        // Update particles with perspective
        if particlesHidden {
            for pr in particles {
                pr.node.isHidden = true
            }
        } else {
            // subtle center glow pulse during expansion peak
            if ct >= buildEnd && ct < expandEnd {
                let p = (ct - buildEnd) / (expandEnd - buildEnd)
                if p > 0.85 {
                    centerGlow.alpha = (1 - p) * 0.12
                    centerGlow.size = CGSize(width: 80 + p*140, height: 80 + p*140)
                }
            }
            
            for pr in particles {
                let n = pr.node
                n.isHidden = false
                n.color = globalColor
                
                let effectiveZ = pr.zDepth + zSpread * pr.zVelocity
                let clampedZ = max(-1, min(1, effectiveZ))
                
                // FIX 3: keep max effective radius inside screen
                let perspectiveScale = 1.0 + clampedZ * 0.40 // 0.6 ... 1.4 (was 0.7)
                
                let baseR = pr.targetR * globalRadiusScale
                let baseX = centerPoint.x + cos(pr.angle) * baseR
                let baseY = centerPoint.y + sin(pr.angle) * baseR
                
                let offsetFromCenter = CGPoint(
                    x: baseX - centerPoint.x,
                    y: baseY - centerPoint.y
                )
                
                let scaledPosition = CGPoint(
                    x: centerPoint.x + offsetFromCenter.x * perspectiveScale,
                    y: centerPoint.y + offsetFromCenter.y * perspectiveScale
                )
                
                n.position = scaledPosition
                
                // FIX 2: size with global length/width that decreases outward
                let sizeScale = perspectiveScale
                let h = pr.baseLen * globalLengthScale * sizeScale
                let w = pr.baseWid * globalWidthScale * sizeScale
                n.size = CGSize(width: max(0.7, w), height: max(1.2, h))
                
                // alpha: front brighter, back dimmer — but keep inner core visible
                let depthAlpha = 0.62 + (clampedZ + 1) / 2 * 0.38
                n.alpha = globalAlpha * depthAlpha
                n.zPosition = -clampedZ * 10
            }
        }
        
        // Update bg streaks alpha smoothly (no jump)
        var bgAlpha: CGFloat = 1
        if ct >= buildEnd && ct < expandEnd {
            let p = (ct - buildEnd) / (expandEnd - buildEnd)
            if p > 0.30 && p < 0.88 {
                bgAlpha = lerp(1.0, 0.42, easeOutQuad( (p - 0.30)/0.58 ))
            } else if p >= 0.88 {
                bgAlpha = lerp(0.42, 0.88, (p - 0.88)/0.12)
            }
        } else if ct >= expandEnd && ct < collapseEnd {
            let p = (ct - expandEnd)/(collapseEnd - expandEnd)
            bgAlpha = 0.88 + 0.12 * p
        }
        bgStreaksNode.alpha = bgAlpha
    }
}
