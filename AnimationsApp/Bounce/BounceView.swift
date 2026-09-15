import SwiftUI
import RealityKit
import simd
import UIKit

// MARK: - BounceView

struct BounceView: View {
    @State private var scene = BounceScene()

    var body: some View {
        ZStack {
            Color(red: 0.88, green: 0.89, blue: 0.93)
                .ignoresSafeArea()

            RealityView { content in
                scene.buildScene()
                content.add(scene.root)

                let camera = scene.makeCamera()
                content.add(camera)

                for light in scene.makeLights() {
                    content.add(light)
                }

                scene.subscription = content.subscribe(
                    to: SceneEvents.Update.self
                ) { event in
                    scene.update(deltaTime: Float(event.deltaTime))
                }
            }
            .ignoresSafeArea()
        }
    }
}
