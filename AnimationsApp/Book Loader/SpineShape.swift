//
//  SpineShape.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 17/09/26.
//

import SwiftUI

struct SpineShape: Shape {
    var openSwing: Angle
    var closeSwing: Angle = .degrees(0)
    var closing: Bool = false
    var radius: CGFloat = 30

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(openSwing.degrees, closeSwing.degrees) }
        set {
            openSwing = .degrees(newValue.first)
            closeSwing = .degrees(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        let hx = rect.midX - 20
        let hy = rect.midY + 60
        var p = Path()
        
        if !closing {
            let t = openSwing.radians
            let cx = hx + radius * sin(t)
            let cy = hy - radius * cos(t)
            p.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: radius,
                startAngle: .degrees(-90) + openSwing,
                endAngle: .degrees(90) + openSwing,
                clockwise: false
            )
        } else {
            
            let tx = hx + 2 * radius
            let ty = hy
            let u = closeSwing.radians
            let cx = tx - radius * cos(u)
            let cy = ty - radius * sin(u)
            p.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: radius,
                startAngle: closeSwing,
                endAngle: closeSwing + .degrees(180),
                clockwise: false
            )
        }
        return p
    }
}
