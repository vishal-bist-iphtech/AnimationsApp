//
//  BounceScene.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 11/09/26.
//

import RealityKit
import SwiftUI
import simd

final class BounceScene {
    
    var root = Entity()
    var innerDisk: Entity?
    var balls: [ModelEntity] = []
    var outerPositions: [SIMD3<Float>] = []
    var innerPositions: [SIMD3<Float>] = []
    
    var subscription: EventSubscription?
    
    let baseRadius: Float = 1.18
    let baseHeight: Float = 0.92
    
    let diskRadius: Float = 1.05
    let diskHeight: Float = 0.48
    
    let holeDepth: Float = 0.25
    
    let outerRingRadius: Float = 0.82
    let innerRingRadius: Float = 0.47
    let holeRadius: Float = 0.112
    let ballRadius: Float = 0.092
    
    // Animation constants
    var elapsed: Float = 0
    let loopDuration: Float = 3.4
    let flightDuration: Float = 0.58
    let stagger: Float = 0.098
    let startDelay: Float = 0.06
    let liftAmount: Float = 0.22
    let sinkDepth: Float = 0.025
    
    // Disk lift timing
    let riseDur: Float = 0.12
    let holdUntil: Float = 0.20
    let fallDur: Float = 0.68
    
    // MARK: Build
    
    func buildScene() {
        root = Entity()
        root.name = "Root"
        
        // OuterBase
        // MARK: - OuterBase (hollow container)
        
        let outerBase = Entity()
        outerBase.name = "OuterBase"
        root.addChild(outerBase)
        
        var baseMaterial = SimpleMaterial(
            color: UIColor(white: 0.96, alpha: 1.0),
            isMetallic: false
        )
        baseMaterial.roughness = 0.72
        
        // Outer wall
        let outerWallMesh = makeCylinderWall(
            radius: baseRadius,
            height: baseHeight,
            inward: false
        )
        
        let outerWall = ModelEntity(
            mesh: outerWallMesh,
            materials: [baseMaterial]
        )
        
        outerWall.position.y = baseHeight / 2
        outerBase.addChild(outerWall)
        
        
        // Bottom of OuterBase
        let outerBottomMesh = MeshResource.generateCylinder(
            height: 0.05,
            radius: baseRadius
        )
        
        let outerBottom = ModelEntity(
            mesh: outerBottomMesh,
            materials: [baseMaterial]
        )
        
        outerBottom.position.y = 0.025
        outerBase.addChild(outerBottom)
        
        
        // MARK: - Hole position cache
        
        outerPositions.removeAll()
        innerPositions.removeAll()
        
        for i in 0..<8 {
            
            let angle = -Float.pi / 2
            + Float(i) / 8 * 2 * Float.pi
            
            let ox = cos(angle) * outerRingRadius
            let oz = sin(angle) * outerRingRadius
            
            let ix = cos(angle) * innerRingRadius
            let iz = sin(angle) * innerRingRadius
            
            outerPositions.append(
                SIMD3(ox, 0, oz)
            )
            
            innerPositions.append(
                SIMD3(ix, 0, iz)
            )
        }
        
        
        // MARK: - InnerBase
        
        let innerBase = Entity()
        innerBase.name = "InnerBase"
        
        // InnerBase starts INSIDE OuterBase
        innerBase.position = SIMD3(
            0,
            baseHeight - diskHeight / 2,
            0
        )
        
        root.addChild(innerBase)
        innerDisk = innerBase
        
        
        var innerMaterial = SimpleMaterial(
            color: UIColor(white: 0.985, alpha: 1.0),
            isMetallic: false
        )
        
        innerMaterial.roughness = 0.60
        
        
        // Outer wall of InnerBase
        let innerWallMesh = makeCylinderWall(
            radius: diskRadius,
            height: diskHeight,
            inward: false
        )
        
        let innerWall = ModelEntity(
            mesh: innerWallMesh,
            materials: [innerMaterial]
        )
        
        innerBase.addChild(innerWall)
        
        
        // Bottom of InnerBase
        let innerBottomMesh = MeshResource.generateCylinder(
            height: 0.04,
            radius: diskRadius
        )
        
        let innerBottom = ModelEntity(
            mesh: innerBottomMesh,
            materials: [innerMaterial]
        )
        
        innerBottom.position.y = -diskHeight / 2 + 0.02
        
        innerBase.addChild(innerBottom)
        
        
        // MARK: - Top surface with 16 openings
        
        let topSurfaceMesh = makeTopCapWithHoles()
        
        let topSurface = ModelEntity(
            mesh: topSurfaceMesh,
            materials: [innerMaterial]
        )
        
        topSurface.position.y = diskHeight / 2
        
        innerBase.addChild(topSurface)
        
        
        // MARK: - Deep hole cavities
        
        for pos in outerPositions + innerPositions {
            
            // Deep inner wall of hole
            let holeWallMesh = makeCylinderWall(
                radius: holeRadius,
                height: holeDepth,
                inward: true
            )
            
            var holeMaterial = SimpleMaterial(
                color: UIColor(white: 0.94, alpha: 1.0),
                isMetallic: false
            )
            
            holeMaterial.roughness = 0.8
            
            let holeWall = ModelEntity(
                mesh: holeWallMesh,
                materials: [holeMaterial]
            )
            
            // Starts at top and goes downward
            holeWall.position = SIMD3(
                pos.x,
                diskHeight / 2 - holeDepth / 2,
                pos.z
            )
            
            innerBase.addChild(holeWall)
            
            
            // Bottom of cavity
            let holeBottomMesh = MeshResource.generateCylinder(
                height: 0.01,
                radius: holeRadius * 0.96
            )
            
            let holeBottom = ModelEntity(
                mesh: holeBottomMesh,
                materials: [holeMaterial]
            )
            
            holeBottom.position = SIMD3(
                pos.x,
                diskHeight / 2 - holeDepth,
                pos.z
            )
            
            innerBase.addChild(holeBottom)
            
            
            // Rounded rim
            let rimMesh = makeRingMesh(
                innerRadius: holeRadius,
                outerRadius: holeRadius + 0.018,
                y: 0
            )
            
            let rim = ModelEntity(
                mesh: rimMesh,
                materials: [innerMaterial]
            )
            
            rim.position = SIMD3(
                pos.x,
                diskHeight / 2 + 0.001,
                pos.z
            )
            
            innerBase.addChild(rim)
        }

        // MARK: - Balls

        balls.removeAll()

        let ballMesh = MeshResource.generateSphere(radius: ballRadius)

        var ballMaterial = SimpleMaterial(
            color: UIColor(red: 0.94, green: 0.28, blue: 0.12, alpha: 1.0),
            isMetallic: false
        )
        ballMaterial.roughness = 0.45

        for _ in 0..<8 {
            let ball = ModelEntity(
                mesh: ballMesh,
                materials: [ballMaterial]
            )
            ball.isEnabled = false
            root.addChild(ball)
            balls.append(ball)
        }
    }

        // MARK: Holes helpers – hollow cylinders
        
        func makeCylinderWall(radius: Float, height: Float, inward: Bool = true, segments: Int = 48) -> MeshResource {
            var positions: [SIMD3<Float>] = []
            var normals: [SIMD3<Float>] = []
            var indices: [UInt32] = []
            let halfH = height / 2
            for i in 0..<segments {
                let ang = Float(i) / Float(segments) * 2 * Float.pi
                let x = cos(ang); let z = sin(ang)
                let nx: Float = inward ? -x : x
                let nz: Float = inward ? -z : z
                // top
                positions.append(SIMD3(radius * x, halfH, radius * z))
                normals.append(SIMD3(nx, 0, nz))
                // bottom
                positions.append(SIMD3(radius * x, -halfH, radius * z))
                normals.append(SIMD3(nx, 0, nz))
            }
            for i in 0..<segments {
                let next = (i+1) % segments
                let topCurr = UInt32(i*2)
                let botCurr = UInt32(i*2+1)
                let topNext = UInt32(next*2)
                let botNext = UInt32(next*2+1)
                indices.append(topCurr); indices.append(botCurr); indices.append(topNext)
                indices.append(botCurr); indices.append(botNext); indices.append(topNext)
            }
            var desc = MeshDescriptor()
            desc.positions = MeshBuffers.Positions(positions)
            desc.normals = MeshBuffers.Normals(normals)
            desc.primitives = .triangles(indices)
            return try! MeshResource.generate(from: [desc])
        }
        
        func makeTopCapWithHoles() -> MeshResource {
            // Grid-based flat disc with 16 circular cutouts – approximates true hollow top
            let R = diskRadius
            let hr = holeRadius
            let N: Int = 110
            let cell = 2*R / Float(N)
            let half = cell/2
            var positions: [SIMD3<Float>] = []
            var normals: [SIMD3<Float>] = []
            var indices: [UInt32] = []
            // Hole centers in local disc coords
            let centers = outerPositions + innerPositions
            for ix in 0..<N {
                for iz in 0..<N {
                    let cx = -R + Float(ix)*cell + half
                    let cz = -R + Float(iz)*cell + half
                    let distSq = cx*cx + cz*cz
                    if distSq > (R - half)*(R - half) { continue } // outside disc
                    var insideHole = false
                    for c in centers {
                        let dx = cx - c.x; let dz = cz - c.z
                        if dx*dx + dz*dz < hr*hr { insideHole = true; break }
                    }
                    if insideHole { continue }
                    let base = UInt32(positions.count)
                    let x0 = cx - half; let x1 = cx + half
                    let z0 = cz - half; let z1 = cz + half
                    let y: Float = 0
                    positions.append(SIMD3(x0,y,z0)); normals.append(SIMD3(0,1,0))
                    positions.append(SIMD3(x1,y,z0)); normals.append(SIMD3(0,1,0))
                    positions.append(SIMD3(x1,y,z1)); normals.append(SIMD3(0,1,0))
                    positions.append(SIMD3(x0,y,z1)); normals.append(SIMD3(0,1,0))
                    indices.append(base); indices.append(base+1); indices.append(base+2)
                    indices.append(base); indices.append(base+2); indices.append(base+3)
                }
            }
            var desc = MeshDescriptor()
            desc.positions = MeshBuffers.Positions(positions)
            desc.normals = MeshBuffers.Normals(normals)
            desc.primitives = .triangles(indices)
            return try! MeshResource.generate(from: [desc])
        }
        
        func makeRingMesh(innerRadius: Float, outerRadius: Float, y: Float, segments: Int = 64) -> MeshResource {
            var positions: [SIMD3<Float>] = []
            var normals: [SIMD3<Float>] = []
            var indices: [UInt32] = []
            
            for i in 0..<segments {
                let angle = Float(i) / Float(segments) * 2.0 * .pi
                let x = cos(angle)
                let z = sin(angle)
                positions.append(SIMD3(innerRadius * x, y, innerRadius * z))
                positions.append(SIMD3(outerRadius * x, y, outerRadius * z))
                normals.append(SIMD3(0,1,0))
                normals.append(SIMD3(0,1,0))
            }
            for i in 0..<segments {
                let next = (i+1)%segments
                let innerCurrent = UInt32(i*2)
                let outerCurrent = UInt32(i*2+1)
                let innerNext = UInt32(next*2)
                let outerNext = UInt32(next*2+1)
                indices.append(innerCurrent); indices.append(outerCurrent); indices.append(innerNext)
                indices.append(outerCurrent); indices.append(outerNext); indices.append(innerNext)
            }
            var descriptor = MeshDescriptor()
            descriptor.positions = MeshBuffers.Positions(positions)
            descriptor.normals = MeshBuffers.Normals(normals)
            descriptor.primitives = .triangles(indices)
            return try! MeshResource.generate(from: [descriptor])
        }
        
        // MARK: Camera / Lights
        
        func makeCamera() -> PerspectiveCamera {
            let camera = PerspectiveCamera()
            // Pulled back + wider FOV so outer base fits exactly within mobile width
            let camPos = SIMD3<Float>(0, 6.2, 2.9)
            camera.position = camPos
            camera.look(at: SIMD3<Float>(0, 0.88, 0), from: camPos, relativeTo: nil)
            camera.camera.fieldOfViewInDegrees = 52
            return camera
        }
        
        func makeLights() -> [Entity] {
            // Softer studio lighting – lower intensity to avoid washing out whites
            let key = Entity()
            var keyLight = DirectionalLightComponent()
            keyLight.intensity = 3500
            keyLight.isRealWorldProxy = true
            key.components.set(keyLight)
            key.position = SIMD3(-2.8, 5.5, 2.2)
            key.look(at: SIMD3(0, 0.9, 0), from: key.position, relativeTo: nil)
            
            let fill = Entity()
            var fillLight = DirectionalLightComponent()
            fillLight.intensity = 1400
            fill.components.set(fillLight)
            fill.position = SIMD3(2.5, 4.0, -1.8)
            fill.look(at: SIMD3(0, 0.9, 0), from: fill.position, relativeTo: nil)
            
            let top = Entity()
            var topLight = DirectionalLightComponent()
            topLight.intensity = 800
            top.components.set(topLight)
            top.position = SIMD3(0, 6, 0)
            top.look(at: SIMD3(0,0,0), from: SIMD3(0,6,0), relativeTo: nil)
            
            return [key, fill, top]
        }
        
        // MARK: Animation – Disk lift
        
        func diskOffset(at t: Float) -> Float {
            if t < 0 { return 0 }
            if t < riseDur {
                let u = t / riseDur
                let e = 1 - pow(1 - u, 3) // easeOutCubic
                return e * liftAmount
            } else if t < holdUntil {
                return liftAmount
            } else if t < holdUntil + fallDur {
                let u = (t - holdUntil) / fallDur
                // smooth fall with slight overshoot/bounce at landing
                let easeIn = pow(u, 2.0)
                let bounce = sin(u * Float.pi * 1.65) * 0.016 * (1 - u)
                return liftAmount * (1 - easeIn) + bounce
            } else {
                return 0
            }
        }
        
        // MARK: Per-frame update
        
        func update(deltaTime: Float) {
            elapsed += deltaTime
            
            let t = fmod(elapsed, loopDuration)
            
            // Current vertical movement of InnerBase
            let diskOff = diskOffset(at: t)
            
            // InnerBase starts inside OuterBase
            let innerBaseCenterY =
            baseHeight - diskHeight / 2 + diskOff
            
            // Top surface of InnerBase
            let topYNow =
            innerBaseCenterY + diskHeight / 2
            
            // Move InnerBase
            if let disk = innerDisk {
                disk.position.y = innerBaseCenterY
            }
            
            let globalSinkStart = loopDuration - 0.42
            
            for i in 0..<8 {
                
                let ball = balls[i]
                
                let startXZ = outerPositions[i]
                let endXZ = innerPositions[i]
                
                let delay =
                Float(i) * stagger + startDelay
                
                let ballTime = t - delay
                
                
                // MARK: - Final sinking phase
                
                if t >= globalSinkStart && ballTime >= flightDuration {
                    
                    let sinkProg =
                    (t - globalSinkStart)
                    / (loopDuration - globalSinkStart)
                    
                    let settledY =
                    topYNow - ballRadius * 0.38
                    
                    let deepY =
                    topYNow - holeDepth + ballRadius * 0.15
                    
                    let y =
                    settledY
                    + (deepY - settledY) * sinkProg
                    
                    let scale =
                    1 - sinkProg * 0.35
                    
                    ball.scale =
                    SIMD3(repeating: max(0.1, scale))
                    
                    
                    if sinkProg < 0.88 {
                        
                        ball.isEnabled = true
                        
                        ball.position =
                        SIMD3(
                            endXZ.x,
                            y,
                            endXZ.z
                        )
                        
                    } else {
                        
                        // Hide ball and prepare next loop
                        
                        ball.isEnabled = false
                        
                        let outerHiddenY =
                        baseHeight
                        - holeDepth
                        + 0.05
                        
                        ball.position =
                        SIMD3(
                            startXZ.x,
                            outerHiddenY,
                            startXZ.z
                        )
                        
                        ball.scale =
                        SIMD3(repeating: 1)
                    }
                    
                    continue
                }
                
                
                // MARK: - Waiting before launch
                
                if ballTime < 0 {
                    
                    ball.isEnabled = false
                    
                    ball.scale =
                    SIMD3(repeating: 1)
                    
                    let hiddenY =
                    baseHeight
                    - holeDepth
                    + 0.05
                    
                    ball.position =
                    SIMD3(
                        startXZ.x,
                        hiddenY,
                        startXZ.z
                    )
                }
                
                
                // MARK: - Flying outer → inner
                
                else if ballTime < flightDuration {
                    
                    ball.isEnabled = true
                    
                    ball.scale =
                    SIMD3(repeating: 1)
                    
                    let progress =
                    ballTime / flightDuration
                    
                    
                    // InnerBase height at launch
                    let startOff =
                    diskOffset(at: delay)
                    
                    // InnerBase height at landing
                    let endOff =
                    diskOffset(
                        at: delay + flightDuration
                    )
                    
                    
                    let startY =
                    baseHeight
                    + startOff
                    - ballRadius * 0.22
                    
                    let endY =
                    baseHeight
                    + endOff
                    - ballRadius * 0.38
                    
                    
                    // Horizontal movement
                    
                    let x =
                    startXZ.x
                    + (endXZ.x - startXZ.x) * progress
                    
                    let z =
                    startXZ.z
                    + (endXZ.z - startXZ.z) * progress
                    
                    
                    // Vertical movement
                    
                    let yLinear =
                    startY
                    + (endY - startY) * progress
                    
                    
                    // Parabolic jump
                    
                    let peak: Float = 0.52
                    
                    let arc =
                    4
                    * peak
                    * progress
                    * (1 - progress)
                    
                    let y =
                    yLinear + arc
                    
                    
                    ball.position =
                    SIMD3(
                        x,
                        y,
                        z
                    )
                    
                    
                    // MARK: Ball rotation
                    
                    let dx =
                    endXZ.x - startXZ.x
                    
                    let dz =
                    endXZ.z - startXZ.z
                    
                    let length =
                    sqrt(dx * dx + dz * dz)
                    
                    let dirX =
                    length > 0.0001
                    ? dx / length
                    : 0
                    
                    let dirZ =
                    length > 0.0001
                    ? dz / length
                    : 1
                    
                    let axis =
                    normalize(
                        SIMD3(
                            dirZ,
                            0,
                            -dirX
                        )
                    )
                    
                    let spin =
                    progress
                    * length
                    / max(ballRadius, 0.01)
                    * 1.15
                    
                    ball.orientation =
                    simd_quatf(
                        angle: spin,
                        axis: axis
                    )
                }
                
                
                // MARK: - Landing bounce
                
                else if ballTime < flightDuration + 0.32 {
                    
                    ball.isEnabled = true
                    
                    ball.scale =
                    SIMD3(repeating: 1)
                    
                    let bounceT =
                    (ballTime - flightDuration)
                    / 0.32
                    
                    let settledY =
                    topYNow
                    - ballRadius * 0.38
                    
                    let bounce =
                    sin(bounceT * Float.pi)
                    * 0.055
                    * (1 - bounceT * 0.4)
                    
                    ball.position =
                    SIMD3(
                        endXZ.x,
                        settledY + bounce,
                        endXZ.z
                    )
                }
                
                
                // MARK: - Settled in inner hole
                
                else {
                    
                    ball.isEnabled = true
                    
                    ball.scale =
                    SIMD3(repeating: 1)
                    
                    let settledY =
                    topYNow
                    - ballRadius * 0.38
                    
                    ball.position =
                    SIMD3(
                        endXZ.x,
                        settledY,
                        endXZ.z
                    )
                    
                    ball.orientation =
                    simd_quatf(
                        angle: 0,
                        axis: SIMD3(0, 1, 0)
                    )
                }
            }
        }
}
