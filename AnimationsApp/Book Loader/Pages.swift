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
        let flipPageW = width * BookLayout.pageWidthFactor
        let flipBaseY = spineHy - page1OffsetFromTopCover - BookLayout.pageThickness
        // p is progress.
        // Forward: hinge left->right, angle 0->180
        // Reversed: hinge right->left, angle 180->0
        let p = flip
        let travel = reversed ? 1 - p : p
        let flipHX = spineHx + (2 * radius) * travel
        let flipHY = flipBaseY - BookFlip.liftHeight * CGFloat(sin(Double.pi * Double(p))) + yOffset
        let fadeIn = min(max(p / BookFlip.fadeInEnd, 0), 1)
        let fadeOut = p > BookFlip.fadeOutStart ? max(0, 1 - (p - BookFlip.fadeOutStart) / BookFlip.fadeOutRange) : 1
        
        let jointOverlap: CGFloat = BookLayout.jointOverlap
        let flipAngle = Angle.degrees(BookSwing.fullFlip * Double(travel))
        let overlapX = cos(flipAngle.radians) * jointOverlap
        let overlapY = sin(flipAngle.radians) * jointOverlap

        return Capsule()
            .fill(.white)
            .frame(width: flipPageW, height: BookLayout.pageThickness)
            .rotationEffect(flipAngle, anchor: .trailing)
            .position(x: flipHX + overlapX - flipPageW / 2, y: flipHY + overlapY)
            .opacity(fadeIn * fadeOut)
    }
}
