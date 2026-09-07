import SwiftUI
import RealityKit


struct StarburstView: View {
    
    @State private var starburst = StarburstScene(particleCount: 100)
    
    var body: some View {
        
    /* RealityView{ content in} :- Hosting 3D content in SwiftUI app
                                   Managing RealityKit scenes within the SwiftUI lifecycle
                                   Creating AR/VR experiences with minimal boilerplate */
        RealityView{ content in
            
            for droplet in starburst.particleEntities {
                content.add(droplet.entity)
            }
            
            // every time realitykit renders a frame, update the particles
            starburst.udpateSubscription =
            content.subscribe(to: SceneEvents.Update.self) { event in
                
                // deltaTime = time ellapsed between frames in sec
                let deltaTime = Float(event.deltaTime)
                
                starburst.update(deltaTime: deltaTime)
            }
        }
        .background(.black)
    }
}


#Preview {
    StarburstView()
}
