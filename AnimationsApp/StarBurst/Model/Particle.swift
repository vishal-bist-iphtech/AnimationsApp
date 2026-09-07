//
//  Particle.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 04/09/26.
//

import Foundation
import simd


struct Particle {
    
    var position: SIMD3<Float>
    var direction: SIMD3<Float>
    var velocity: SIMD3<Float>
        
    var initialSpeed: Float
    var lifetime: Float
    var age: Float
    var size: Float
}
