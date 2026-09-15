//
//  ContentView.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 02/09/26.
//

import SwiftUI
 import RealityKit

struct ContentView: View {
    
    var body: some View {
        // --- Starburst RealityKit animation ---
//        StarburstView()
//            .ignoresSafeArea()
        
        // --- Bounce RealityKit animation ---
//        BounceView()
//            .ignoresSafeArea()
        
        BookLoaderView()
            .ignoresSafeArea()

    }
}

#Preview {
    ContentView()
}
