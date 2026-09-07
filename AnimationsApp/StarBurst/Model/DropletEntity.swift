//
//  Droplet.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 04/09/26.
//

import SwiftUI
import RealityKit
import simd

final class DropletEntity {
    
    let entity: Entity
    
    private let head: ModelEntity
    private let tail: ModelEntity
    private let headRadius: Float
    
    private let baseTailLength: Float
    
    init(size: Float = 0.015) {
        entity = Entity()
        
        self.headRadius = size

        let tailLength = size * 20
        
        let headMesh = MeshResource.generateSphere(radius: size)
        let tailMesh = MeshResource.generateCone(height: tailLength, radius: size * 0.9)

        let material = SimpleMaterial(color: .white, isMetallic: false)

        head = ModelEntity(mesh: headMesh, materials: [material])
        tail = ModelEntity(mesh: tailMesh, materials: [material])
        
        head.position = .zero
        tail.position = SIMD3<Float>(0, tailLength/2 + size, 0)
           
        baseTailLength = tailLength
        
        entity.addChild(head)
        entity.addChild(tail)
    }
    
   
    
    func update(
        position: SIMD3<Float>,
        velocity: SIMD3<Float>
    ) {
        
        entity.position = position
        
        let speed = simd_length(velocity)
        
        guard speed > 0.001 else {
            tail.isEnabled = false
            return
        }
        
        tail.isEnabled = true
        
        let tailLength = speed * 0.4
        
        tail.position = SIMD3<Float>(0, tailLength/2 + headRadius, 0)
        
        let tailScale = tailLength / baseTailLength
        
        tail.scale = SIMD3<Float>(1, tailScale, 1)
        
        let direction = -simd_normalize(velocity)
        
        entity.orientation = simd_quatf(
            from: SIMD3<Float>(0,1,0),
            to: direction
        )
    }
}
