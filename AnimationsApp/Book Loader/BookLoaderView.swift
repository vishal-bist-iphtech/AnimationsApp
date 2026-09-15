//
//  BookLoaderView.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 15/09/26.
//

import SwiftUI

struct BookLoaderView: View {
    
    @State private var progress: CGFloat = 0
    
    
    var body: some View {
        
        GeometryReader { geometry in
            
            let width = geometry.size.width
            let height = geometry.size.height
            
            let hingeX = width / 2
            let hingeY = height / 2
            
            
            ZStack {
                
                Color.blue
                    .ignoresSafeArea()
                        
                
                // MARK: - Opening angle
                let openingAngle = Angle(degrees: 90 * progress)


                // MARK: - Top Cover
                Capsule()
                    .fill(.white)
                    .frame(
                        width: width * 0.35,
                        height: 15
                    )
                    .position(
                        x: hingeX - (width * 0.35) / 2,
                        y: hingeY
                    )
                    .rotationEffect(
                        openingAngle,
                        anchor: .center
                    )


                // MARK: - Page 1
                Capsule()
                    .fill(.white)
                    .frame(
                        width: width * 0.25,
                        height: 8
                    )
                    .position(
                        x: hingeX - (width * 0.40) / 2,
                        y: hingeY + 22
                    )
                    .rotationEffect(
                        openingAngle,
                        anchor: .center
                    )
                
                
                // MARK: Spine
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(
                        .white,
                        style: StrokeStyle(
                            lineWidth: 15,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(
                        Angle(degrees: -90),
                        anchor: .center
                    )
                    .position(
                        x: width/2 - 15,
                        y: height/2 + 30
                    )
                
                
                // MARK: - Page 2
                Capsule()
                    .fill(.white)
                    .frame(
                        width: width * 0.25,
                        height: 8
                    )
                    .position(
                        x: hingeX - (width * 0.40) / 2,
                        y: hingeY + 38
                    )
                
                // MARK: Bottom Cover
                Capsule()
                    .fill(.white)
                    .frame(
                        width: width * 0.35,
                        height: 15
                    )
                    .position(
                        x: hingeX - (width * 0.35) / 2,
                        y: hingeY + 60
                    )
                
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 1.0)) {
                    progress = progress == 0 ? 1 : 0
                }
            }
        }
    }
}

#Preview {
    BookLoaderView()
}
