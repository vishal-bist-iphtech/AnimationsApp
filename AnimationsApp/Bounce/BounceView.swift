import SwiftUI
import RealityKit

struct BounceView: View {

    var body: some View {

        RealityView { content in

            let scene = makeScene()

            content.add(scene)

            let camera = makeCamera()
            content.add(camera)
        }
        .ignoresSafeArea()
    }


    // MARK: - Scene

    private func makeScene() -> Entity {

        let root = Entity()

        let base = makeBaseCylinder()
        root.addChild(base)

        let upperCylinder = makeUpperCylinder()
        root.addChild(upperCylinder)

        let light = makeLight()
        root.addChild(light)

        return root
    }


    // MARK: - Lower Base Cylinder

    private func makeBaseCylinder() -> ModelEntity {

        let radius: Float = 1.55
        let height: Float = 0.55

        let mesh = MeshResource.generateCylinder(
            height: height,
            radius: radius
        )

        var material = SimpleMaterial(
            color: .darkGray,
            isMetallic: false
        )

        material.roughness = 0.8

        let base = ModelEntity(
            mesh: mesh,
            materials: [material]
        )

        // Bottom of the base is at Y = 0
        base.position.y = height / 2

        return base
    }


    // MARK: - Upper Revolver Cylinder

    private func makeUpperCylinder() -> ModelEntity {

        let radius: Float = 1.47
        let height: Float = 0.16

        let mesh = MeshResource.generateCylinder(
            height: height,
            radius: radius
        )

        var material = SimpleMaterial(
            color: .white,
            isMetallic: false
        )

        material.roughness = 0.75

        let upperCylinder = ModelEntity(
            mesh: mesh,
            materials: [material]
        )

        let baseHeight: Float = 0.55

        upperCylinder.position.y =
            baseHeight + height / 2

        // Add the 16 recessed holes
        addHoles(
            to: upperCylinder,
            diskRadius: radius,
            diskHeight: height
        )

        return upperCylinder
    }
    
    private func addHoles(
        to revolver: ModelEntity,
        diskRadius: Float,
        diskHeight: Float
    ) {

        let outerRingRadius: Float = 1.08
        let innerRingRadius: Float = 0.60

        let holeRadius: Float = 0.17

        // 8 outer holes
        for index in 0..<8 {

            let angle =
                Float(index) / 8.0 * 2.0 * .pi

            let x = cos(angle) * outerRingRadius
            let z = sin(angle) * outerRingRadius

            let hole = makeRecessedHole(
                radius: holeRadius,
                depth: 0.10,
                diskHeight: diskHeight
            )

            hole.position = SIMD3(
                x,
                0,
                z
            )

            revolver.addChild(hole)
        }

        // 8 inner holes - aligned with outer holes (same angle, different radius)
        for index in 0..<8 {

            let angle =
                Float(index) / 8.0 * 2.0 * .pi

            let x = cos(angle) * innerRingRadius
            let z = sin(angle) * innerRingRadius

            let hole = makeRecessedHole(
                radius: holeRadius,
                depth: 0.10,
                diskHeight: diskHeight
            )

            hole.position = SIMD3(
                x,
                0,
                z
            )

            revolver.addChild(hole)
        }
    }
    
    private func makeRecessedHole(
        radius: Float,
        depth: Float,
        diskHeight: Float
    ) -> Entity {

        let holeRoot = Entity()

        // MARK: Dark recessed interior

        let cavityHeight: Float = 0.025

        let cavityMesh = MeshResource.generateCylinder(
            height: cavityHeight,
            radius: radius
        )

        var cavityMaterial = SimpleMaterial(
            color: .black,
            isMetallic: false
        )

        cavityMaterial.roughness = 1.0

        let cavity = ModelEntity(
            mesh: cavityMesh,
            materials: [cavityMaterial]
        )

        // Top of the revolver cylinder (cylinder mesh is centered at origin)
        let topSurface = diskHeight / 2

        // IMPORTANT: The white cylinder's top face is opaque at y = topSurface.
        // Anything fully BELOW that is inside the mesh and depth-occluded -> invisible.
        // So the dark cavity must intersect the surface: partly inside for depth,
        // partly above so the top face is visible. Like a decal that slightly sinks in.
        cavity.position.y =
            topSurface + cavityHeight/2 - 0.008

        holeRoot.addChild(cavity)


        // MARK: White circular rim

        let rimOuterRadius = radius + 0.035

        let rimMesh = makeRingMesh(
            innerRadius: radius,
            outerRadius: rimOuterRadius,
            y: 0
        )

        var rimMaterial = SimpleMaterial(
            color: UIColor(white: 0.92, alpha: 1.0),
            isMetallic: false
        )

        rimMaterial.roughness = 0.7

        let rim = ModelEntity(
            mesh: rimMesh,
            materials: [rimMaterial]
        )

        // Rim must also be ABOVE the top face, slightly above the cavity to avoid z-fighting
        rim.position.y =
            topSurface + 0.0035

        holeRoot.addChild(rim)

        return holeRoot
    }
    
    // MARK: Camera
    
    private func makeCamera() -> PerspectiveCamera {

        let camera = PerspectiveCamera()

        let cameraPosition = SIMD3<Float>(
            0,
            7.5,
            3.0
        )

        camera.position = cameraPosition

        camera.look(
            at: SIMD3<Float>(0, 0.5, 0),
            from: cameraPosition,
            relativeTo: nil
        )

        camera.camera.fieldOfViewInDegrees = 45

        return camera
    }


    // MARK: - Lighting

    private func makeLight() -> Entity {

        let lightEntity = Entity()

        var light = DirectionalLightComponent()

        light.intensity = 10000

        lightEntity.components.set(light)

        lightEntity.position = SIMD3(
            -3,
            6,
            4
        )

        lightEntity.look(
            at: SIMD3(0, 0, 0),
            from: lightEntity.position,
            relativeTo: nil
        )

        return lightEntity
    }
}


#Preview {
    BounceView()
}
