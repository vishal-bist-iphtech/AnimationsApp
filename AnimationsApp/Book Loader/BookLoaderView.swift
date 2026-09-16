//
//  BookLoaderView.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 15/09/26.
//

//
//  BookLoaderView.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 15/09/26.
//

import SwiftUI

struct BookLoaderView: View {
    
    @State private var progress: CGFloat = 1 // TEST-ONLY: start open
    @State private var flip: CGFloat = 0
    @State private var flipLooping = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            let hingeX = width / 2
            let hingeY = height / 2
            
            // Spine geometry
            let spineHx = width / 2 - 15
            let spineHy = height / 2 + 60
            let radius: CGFloat = 30
            
            ZStack {
                Color.blue.ignoresSafeArea()
                
                // MARK: - Phases
                let openPhase   = min(max(progress / 0.5, 0), 1)
                let swingPhase  = min(max((progress - 0.5) / 0.5, 0), 1)
                let openingAngle = Angle(degrees: 180 * openPhase)
                let spineSwing   = Angle(degrees: 90 * swingPhase)
                
                // MARK: - Spine arc geometry
                let t = spineSwing.radians
                let cx = spineHx + radius * sin(t)
                let cy = spineHy - radius * cos(t)
                
                let trailAngle = -Double.pi / 2 + t
                let trailX = cx + radius * cos(trailAngle)
                let trailY = cy + radius * sin(trailAngle)
                let trailPoint = CGPoint(x: trailX, y: trailY)
                
                // MARK: - Shared layout constants

                let coverThickness: CGFloat = 15
                
                let page1OffsetFromTopCover: CGFloat = 22
                
                let topCoverRotation = Angle(degrees: 180 * swingPhase)
                
                // MARK: - Top Cover
                Capsule()
                    .fill(.white)
                    .frame(width: width * 0.35, height: coverThickness)
                    .rotationEffect(topCoverRotation, anchor: .trailing)
                    .position(
                        x: trailPoint.x - (width * 0.35) / 2,
                        y: trailPoint.y
                    )
                
                // MARK: - Page 1
                let offsetRad = topCoverRotation.radians
                // Rotate (0, +offset) by topCoverRotation
                let offX = -sin(offsetRad) * page1OffsetFromTopCover
                let offY =  cos(offsetRad) * page1OffsetFromTopCover
                
                let page1TrailX = trailPoint.x + offX
                let page1TrailY = trailPoint.y + offY
                
                Capsule()
                    .fill(.white)
                    .frame(width: width * 0.30, height: 8)
                    .rotationEffect(topCoverRotation, anchor: .trailing)
                    .position(
                        x: page1TrailX - width * 0.30 / 2,
                        y: page1TrailY
                    )
                
                // MARK: - Spine
                HingedSpineShape(swing: spineSwing)
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: 15,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: width, height: height)
                
                
                // MARK: - Page 2
                Capsule()
                    .fill(.white)
                    .frame(width: width * 0.30, height: 8)
                    .position(
                        x: spineHx - width * 0.30 / 2,
                        y: hingeY + 38
                    )
                
                
                // MARK: - Bottom Cover
                Capsule()
                    .fill(.white)
                    .frame(width: width * 0.35, height: coverThickness)
                    .position(
                        x: hingeX - (width * 0.40) / 2,
                        y: hingeY + 60
                    )
                
                // MARK: - Flip Page (loader)
                // Shown only once the book is open. Starts identical to
                // Page 2 but a little above it, arcs over to the right and
                // lands just above Page 1 with a slight fade.
                let bookOpen = swingPhase >= 0.999
                let flipPageW = width * 0.30
                let flipLiftAbovePages: CGFloat = 8
                let flipArcHeight: CGFloat = 30
                let flipLeftX = spineHx
                let flipRightX = spineHx + 2 * radius
                let flipBaseY = spineHy - page1OffsetFromTopCover - flipLiftAbovePages
                let flipHX = flipLeftX + (flipRightX - flipLeftX) * flip
                let flipArcLift = flipArcHeight * CGFloat(sin(Double.pi * Double(flip)))
                let flipHY = flipBaseY - flipArcLift
                let flipOpacity: CGFloat = {
                    guard bookOpen else { return 0 }
                    let fadeIn = min(max(flip / 0.12, 0), 1)
                    let fadeOut = flip > 0.82 ? max(0, 1 - (flip - 0.82) / 0.18) : 1
                    return fadeIn * fadeOut
                }()
                
                Capsule()
                    .fill(.white)
                    .frame(width: flipPageW, height: 8)
                    .rotationEffect(.degrees(180 * flip), anchor: .trailing)
                    .position(x: flipHX - flipPageW / 2, y: flipHY)
                    .opacity(flipOpacity)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 2.0)) {
                    progress = progress == 0 ? 1.0 : 0
                }
            }
            .task { // TEST-ONLY: start flip loop immediately
                guard !flipLooping else { return }
                flipLooping = true
                flip = 0
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    flip = 1
                }
            }
            .onChange(of: progress) { _, p in
                if p >= 1.0 {
                    // The book-open animation runs ~2s; start flipping only
                    // after it completes. (The delay lives here and NOT in
                    // the repeating animation — .delay + .repeatForever
                    // combined never starts.)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        guard progress >= 1.0, !flipLooping else { return }
                        flipLooping = true
                        flip = 0
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                            flip = 1
                        }
                    }
                } else if flipLooping {
                    flipLooping = false
                    withAnimation(.easeOut(duration: 0.25)) {
                        flip = 0
                    }
                }
            }
        }
    }
}

#Preview {
    BookLoaderView()
}

// MARK: - Hinged spine
struct HingedSpineShape: Shape {
    var swing: Angle
    var radius: CGFloat = 30

    var animatableData: Double {
        get { swing.degrees }
        set { swing = .degrees(newValue) }
    }

    func path(in rect: CGRect) -> Path {
        let hx = rect.midX - 15
        let hy = rect.midY + 60
        let t = swing.radians
        
        let cx = hx + radius * sin(t)
        let cy = hy - radius * cos(t)
        var p = Path()
        
        p.addArc(
            center: CGPoint(x: cx, y: cy),
            radius: radius,
            startAngle: .degrees(-90) + swing,
            endAngle: .degrees(90) + swing,
            clockwise: false
        )
        return p
    }
}
