//
//  Extension.swift
//  AnimationsApp
//
//  Created by iPHTech 34 on 07/09/26.
//

import RealityKit

extension BounceView {
    
    func makeRingMesh(
        innerRadius: Float,
        outerRadius: Float,
        y: Float,
        segments: Int = 64
    ) -> MeshResource {

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []

        for i in 0..<segments {

            let angle =
                Float(i) / Float(segments) * 2.0 * .pi

            let x = cos(angle)
            let z = sin(angle)

            // Inner vertex
            positions.append(
                SIMD3(
                    innerRadius * x,
                    y,
                    innerRadius * z
                )
            )

            // Outer vertex
            positions.append(
                SIMD3(
                    outerRadius * x,
                    y,
                    outerRadius * z
                )
            )

            normals.append(
                SIMD3(0, 1, 0)
            )

            normals.append(
                SIMD3(0, 1, 0)
            )
        }


        for i in 0..<segments {

            let next =
                (i + 1) % segments

            let innerCurrent =
                UInt32(i * 2)

            let outerCurrent =
                UInt32(i * 2 + 1)

            let innerNext =
                UInt32(next * 2)

            let outerNext =
                UInt32(next * 2 + 1)


            // Triangle 1
            indices.append(innerCurrent)
            indices.append(outerCurrent)
            indices.append(innerNext)

            // Triangle 2
            indices.append(outerCurrent)
            indices.append(outerNext)
            indices.append(innerNext)
        }


        var descriptor = MeshDescriptor()

        descriptor.positions =
            MeshBuffers.Positions(positions)

        descriptor.normals =
            MeshBuffers.Normals(normals)

        descriptor.primitives =
            .triangles(indices)

        return try! MeshResource.generate(
            from: [descriptor]
        )
    }
}
