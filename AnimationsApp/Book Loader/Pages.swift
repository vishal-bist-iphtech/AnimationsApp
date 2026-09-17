//
//  Pages.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 17/09/26.
//
import SwiftUI

struct FlipPage: View {
    let flip: CGFloat
    let yOffset: CGFloat
    let width: CGFloat
    let spineHx: CGFloat
    let spineHy: CGFloat
    let radius: CGFloat
    let page1OffsetFromTopCover: CGFloat
    var reversed: Bool = false
    
    var body: some View {
        let flipPageW = width * 0.30
        let flipBaseY = spineHy - page1OffsetFromTopCover - 8
        // p is progress.
        // Forward: hinge left->right, angle 0->180
        // Reversed: hinge right->left, angle 180->0
        let p = flip
        let travel = reversed ? 1 - p : p
        let flipHX = spineHx + (2 * radius) * travel
        let flipHY = flipBaseY - 30 * CGFloat(sin(Double.pi * Double(p))) + yOffset
        let fadeIn = min(max(p / 0.12, 0), 1)
        let fadeOut = p > 0.82 ? max(0, 1 - (p - 0.82) / 0.18) : 1
        
        let jointOverlap: CGFloat = 7
        let flipAngle = Angle.degrees(180 * Double(travel))
        let overlapX = cos(flipAngle.radians) * jointOverlap
        let overlapY = sin(flipAngle.radians) * jointOverlap

        return Capsule()
            .fill(.white)
            .frame(width: flipPageW, height: 8)
            .rotationEffect(flipAngle, anchor: .trailing)
            .position(x: flipHX + overlapX - flipPageW / 2, y: flipHY + overlapY)
            .opacity(fadeIn * fadeOut)
    }
}
