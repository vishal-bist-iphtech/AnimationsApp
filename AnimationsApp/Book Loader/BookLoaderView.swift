//
//  BookLoaderView.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 15/09/26.
//

import SwiftUI

struct BookLoaderView: View {
        
    // constants
    private let openEnd:    Double = 2
    private let closeStart: Double = 4
    private let closeEnd:   Double = 5
    private let reopenStart: Double = 7
    private let reopenEnd:  Double = 8
    private let holdEnd:    Double = 10
    private let cycle:      Double = 12
    
    // SmoothStep function(3r2 - 2r3): easeInOut without using withAnimation
    private func eased(_ x: Double) -> CGFloat {
        let c = min(max(x, 0), 1)
        return CGFloat(c * c * (3 - 2 * c))
    }
    
    var body: some View {
        GeometryReader { geometry in
            
            TimelineView(.animation(minimumInterval: 1 / 60)) { master in
            
                let now = master.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: cycle)
                    
                // MARK: Progress: 0-2 open, 2-10 hold, 10-12 close
                let progress: CGFloat =
                    now < openEnd ? eased(now / 2) :
                    now < holdEnd ? 1 : 1 - eased((now - holdEnd) / 2)
                    
                // spineRotate
                // 0-4 hold, 4-5 close bottom, 5-7 hold flipped,7-8 reopen bottom, 8-12 hold
                let spineRotate: CGFloat =
                    now < closeStart ? 0 :
                    now < closeEnd ? eased(now - closeStart) :
                    now < reopenStart ? 1 :
                    now < reopenEnd ? 1 - eased(now - reopenStart) : 0
                    
                // flip pages only during open
                let bookOpen: Bool = (now > openEnd && now < closeStart) || (now > reopenStart && now < holdEnd)
                let width = geometry.size.width
                let height = geometry.size.height
                
                let hingeX = width / 2
                let hingeY = height / 2
                
                // Spine geometry
                let spineHx = hingeX - 20
                let spineHy = hingeY + 60
                let radius: CGFloat = 30
                
                ZStack {
                    
                    Color.blue
                        .ignoresSafeArea()
                
                    ZStack {
                    
                    // MARK: - Phases
                    let openingPhase  = min(max((progress - 0.5) / 0.5, 0), 1)
                    let openingSwing   = Angle(degrees: 90 * openingPhase)
                    
                    let closingPhase = min(max(spineRotate, 0), 1)
                    let closingSwing = Angle(degrees: 90 * closingPhase)
                    
                    // MARK: - Spine swing arc geometry (trajectory for moving capsules)
                    
                    let t = openingSwing.radians
                    
                    // center of the arc w.r.t "t"
                    let cx = spineHx + radius * sin(t)
                    let cy = spineHy - radius * cos(t)
                    
                    let trailAngle = -Double.pi / 2 + t
                    let trailX = cx + radius * cos(trailAngle)
                    let trailY = cy + radius * sin(trailAngle)
                    let trailPoint = CGPoint(x: trailX, y: trailY)
                        
                    // Open top hinge (fixed pivot for closing).
                    let topHingeX = spineHx + 2 * radius
                    let topHingeY = spineHy
                    
                    let b = closingSwing.radians
                    let bottomHingeX = topHingeX - 2 * radius * cos(b)
                    let bottomHingeY = topHingeY - 2 * radius * sin(b)
                    
                    // MARK: - Shared layout constants

                    let coverThickness: CGFloat = 15
                    
                    let page1OffsetFromTopCover: CGFloat = 22
                    let page2OffsetFromBottomCover: CGFloat = 22
                    
                    let openingAngle = Angle(degrees: 180 * openingPhase)
                    let closingAngle = Angle(degrees: 180 * closingPhase)

                        
                    let jointOverlap: CGFloat = 7
                    // Top pair follows opening hinge trail
                    let overlapX = cos(openingAngle.radians) * jointOverlap
                    let overlapY = sin(openingAngle.radians) * jointOverlap
                    // Bottom pair follows closing hinge trail
                    let closeOverlapX = cos(closingAngle.radians) * jointOverlap
                    let closeOverlapY = sin(closingAngle.radians) * jointOverlap
                    
                    // MARK: - Top Cover
                    Capsule()
                        .fill(.white)
                        .frame(width: width * 0.35, height: coverThickness)
                        .rotationEffect(openingAngle, anchor: .trailing)
                        .position(
                            x: trailPoint.x + overlapX - (width * 0.35) / 2,
                            y: trailPoint.y + overlapY
                        )
                    
                    // MARK: - Page 1
                    let offsetRad = openingAngle.radians
                    // Rotate (0, +offset) by topCoverRotation
                    let offX = -sin(offsetRad) * page1OffsetFromTopCover
                    let offY =  cos(offsetRad) * page1OffsetFromTopCover
                    
                    let page1TrailX = trailPoint.x + offX
                    let page1TrailY = trailPoint.y + offY
                    
                    Capsule()
                        .fill(.white)
                        .frame(width: width * 0.30, height: 8)
                        .rotationEffect(openingAngle, anchor: .trailing)
                        .position(
                            x: page1TrailX + overlapX - width * 0.30 / 2,
                            y: page1TrailY + overlapY
                        )
                    
                    // MARK: - Spine
                        
                    SpineShape(
                        openSwing: openingSwing,
                        closeSwing: closingSwing,
                        closing: spineRotate > 0.001
                    )
                        .stroke(
                            .white,
                            style: StrokeStyle(
                                lineWidth: 15,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .frame(width: width, height: height)
                        
                    let closeRad = closingAngle.radians
                        
                    let page2OffX = page2OffsetFromBottomCover * sin(closeRad)
                    let page2OffY = -page2OffsetFromBottomCover * cos(closeRad)
                    let page2HingeX = bottomHingeX + page2OffX
                    let page2HingeY = bottomHingeY + page2OffY
                    let bottomAnchorX = bottomHingeX + closeOverlapX
                    let bottomAnchorY = bottomHingeY + closeOverlapY
                    let page2AnchorX = page2HingeX + closeOverlapX
                    let page2AnchorY = page2HingeY + closeOverlapY
                    
                    // MARK: - Page 2
                    Capsule()
                        .fill(.white)
                        .frame(width: width * 0.30, height: 8)
                        .rotationEffect(closingAngle, anchor: .trailing)
                        .position(
                            x: page2AnchorX - width * 0.30 / 2,
                            y: page2AnchorY
                        )
                    
                    
                    // MARK: - Bottom Cover
                    Capsule()
                        .fill(.white)
                        .frame(width: width * 0.35, height: coverThickness)
                        .rotationEffect(closingAngle, anchor: .trailing)
                        .position(
                            x: bottomAnchorX - (width * 0.35) / 2,
                            y: bottomAnchorY
                        )
                    
                    // MARK: - Flip Page
                    
                    TimelineView(.animation(minimumInterval: 0.5 / 60)) { timeline in
                        let period: Double = 0.7
                        let raw1 = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: period) / period
       
                        let pageCount = 5
                        
                        let pages = (0..<pageCount).map { i in
                            let raw = (raw1 + Double(i) / Double(pageCount)).truncatingRemainder(dividingBy: 1.0)
                            return CGFloat(raw * raw * (3 - 2 * raw))
                        }

                        // SmoothStep function: easeInOut without using withAnimation
                        let flips: [CGFloat] = (0..<pageCount).map { i in
                            return CGFloat(pages[i] * pages[i] * (3 - 2 * pages[i]))
                        }
                        
                        ZStack {
                            ForEach(Array(flips.enumerated()), id: \.offset) { index, flip in
                                
                                FlipPage(
                                    flip: flip,
                                    yOffset: 0,
                                    width: width,
                                    spineHx: spineHx,
                                    spineHy: spineHy,
                                    radius: radius,
                                    page1OffsetFromTopCover: page1OffsetFromTopCover,
                                    reversed: now >= cycle/2
                                )
                            }
                        }
                        .opacity(bookOpen && spineRotate < 0.01 ? 1 : 0)
                    }
                    
                    }
                    // to center the whole model
                    .offset(x: -10)                
              }
            }
        }
    }
}




#Preview {
    BookLoaderView()
}
