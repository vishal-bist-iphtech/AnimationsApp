//
//  ContentView.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 02/09/26.
//

import SwiftUI
// import SpriteKit // kept for FireworkScene (commented out below)
// import RealityKit // used by Starburst.swift

struct ContentView: View {
    
    // --- FireworkScene configuration (COMMENTED OUT to show Starburst RealityKit animation) ---
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
        // --- Starburst RealityKit animation (as close as video) ---
        StarburstView()
            .ignoresSafeArea()

        /* --- FireworkScene SpriteKit view (COMMENTED OUT) ---
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
