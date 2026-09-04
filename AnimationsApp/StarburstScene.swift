//
//  StarburstScene.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 04/09/26.
//

import SwiftUI
import RealityKit
import simd

final class StarburstScene {
    
    var particles: [Particle] = []
    var particleEntities: [DropletEntity] = []
    var udpateSubscription: EventSubscription?
    
    
    let particleCount: Int
    
    
    
    
    init(particleCount: Int = 500) {
        self.particleCount = particleCount
        
        createParticles()
        createParticleEntities()
    }
    
    
    
    
    
    
    private func randomDirection() -> SIMD3<Float> {
        
        let x = Float.random(in: -1...1)
        let y = Float.random(in: -1...1)
        let z = Float.random(in: -1...1)
        
        let direction = SIMD3<Float>(x, y, z)
        
        // convert into a unit direction
        return simd_normalize(direction)
    }
    
    func createParticles() {
        
        particles.removeAll()
        
        for _ in 0..<particleCount {
            
            let direction = randomDirection()
            
            let initialSpeed = Float.random(in: 1.0...3.0)
            
            let particle = Particle(
                position: .zero,
                direction: direction,
                velocity: direction * initialSpeed,
                initialSpeed: initialSpeed,
                lifetime: Float.random(in: 1.0...2.0),
                age: 0,
                size: Float.random(in: 0.005...0.015)
            )
            
            particles.append(particle)
        }
    }
    
    func createParticleEntities() -> [DropletEntity] {
        
        particleEntities.removeAll()
                    
            var entities: [DropletEntity] = []
            
            for particle in particles {
                
                let droplet = DropletEntity(
                    size: particle.size
                )
                
                droplet.entity.position = particle.position
                
                entities.append(droplet)
            }
            
            particleEntities = entities
            
            return entities
        }
    
    
    
    func update(deltaTime: Float) {
        
        for index in particles.indices {
            
            particles[index].age += deltaTime
            
            let progress = particles[index].age / particles[index].lifetime
            
            let minimumSpeed = particles[index].initialSpeed * 0.15
            
            let currentSpeed = particles[index].initialSpeed * (1.0 - 0.85 * progress)
            
            // check if particle has reached the end of its lifetime
            if particles[index].age >= particles[index].lifetime {
                
                let direction = randomDirection()
                
                let initialSpeed = Float.random(in: 1.0...3.0)
                
                particles[index].position = .zero
                particles[index].velocity = direction * max(currentSpeed, minimumSpeed)
                particles[index].initialSpeed = initialSpeed
                particles[index].lifetime = Float.random(in: 1.0...2.0)
                particles[index].age = 0
                
                particleEntities[index].entity.position = .zero
                
                continue
            }
            
            // new position = old + velocity * time
            particles[index].position += particles[index].velocity * deltaTime
            
            particleEntities[index].update(
                position: particles[index].position,
                velocity: particles[index].velocity
            )
        }
    }
}
