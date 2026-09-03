//
//  ContentView.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 02/09/26.
//

import SwiftUI
// import SpriteKit
 import RealityKit

struct ContentView: View {
    
    // --- FireworkScene configuration ---
    // Kept intact per request — do not delete.
    /*
    @State private var scene: FireworkScene = {
        // Placeholder size — will be replaced by GeometryReader's full-screen size onAppear
        let placeholder = CGSize(width: 390, height: 844)
        let s = FireworkScene(size: placeholder)
        s.scaleMode = .resizeFill
        s.backgroundColor = UIColor(red: 0.035, green: 0.035, blue: 0.075, alpha: 1)
        return s
    }()
    */
    
    var body: some View {
        // --- Starburst RealityKit animation ---
//        StarburstView()
//            .ignoresSafeArea()

        /* --- FireworkScene SpriteKit view ---
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.035, green: 0.035, blue: 0.075)
                    .ignoresSafeArea()
                
                SpriteView(
                    scene: scene,
                    options: [.allowsTransparency]
                )
                .ignoresSafeArea()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear {
                    scene.size = geometry.size
                }
                .onChange(of: geometry.size) { _, newSize in
                    scene.size = newSize
                }
            }
        }
        .ignoresSafeArea()
        */
    }
}

#Preview {
    ContentView()
}
