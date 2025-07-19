//
//  Sample.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import Foundation
import simd

let testingFibulaFragmentGroup = FragmentGroup(
    name: "Real Fibula Scan",
    description: "Fragments mapped from Blender measurements, scaled and offset for ARKit.",
    usdzModelName: "blue-1",
    fragments: [
        Fragment(
            startSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.05, // added 5 cm offeset (from journal)
                xRotationDegrees: -160.911,
                yRotationDegrees: -83.0456,
                zRotationDegrees: 144.811
            ),
            endSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.1104728,
                xRotationDegrees: -1.97443,
                yRotationDegrees: 55.9448,
                zRotationDegrees: 1.21357
            ),
            length: 0.0604728
        ),
        Fragment(
            startSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.1286343,
                xRotationDegrees: -18.093,
                yRotationDegrees: -58.4248,
                zRotationDegrees: 5.21148
            ),
            endSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.1606886,
                xRotationDegrees: -4.2324,
                yRotationDegrees: 59.2235,
                zRotationDegrees: 1.28983
            ),
            length: 0.0320543
        ),
        Fragment(
            startSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.1804378,
                xRotationDegrees: -40.5112,
                yRotationDegrees: -50.6391,
                zRotationDegrees: 35.8737
            ),
            endSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.2273878,
                xRotationDegrees: -27.5019,
                yRotationDegrees: 87.2228,
                zRotationDegrees: -24.0868
            ),
            length: 0.04695
        )
    ]
)

let testFragmentGroup = FragmentGroup(
    name: "Bone White Fibula",
    description: "Fragments mapped from Blender measurements, scaled and offset for ARKit.",
    usdzModelName: "bone-white-1",
    fragments: [
        Fragment(
            startSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.05, // added 5 cm offeset (from journal)
                xRotationDegrees: -160.911,
                yRotationDegrees: -83.0456,
                zRotationDegrees: 144.811
            ),
            endSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.1104728,
                xRotationDegrees: -1.97443,
                yRotationDegrees: 55.9448,
                zRotationDegrees: 1.21357
            ),
            length: 0.0604728
        ),
        Fragment(
            startSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.1286343,
                xRotationDegrees: -18.093,
                yRotationDegrees: -58.4248,
                zRotationDegrees: 5.21148
            ),
            endSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.1606886,
                xRotationDegrees: -4.2324,
                yRotationDegrees: 59.2235,
                zRotationDegrees: 1.28983
            ),
            length: 0.0320543
        ),
        Fragment(
            startSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.1804378,
                xRotationDegrees: -40.5112,
                yRotationDegrees: -50.6391,
                zRotationDegrees: 35.8737
            ),
            endSlice: FragmentSlice(
                distanceFromLeftAnchor: 0.2273878,
                xRotationDegrees: -27.5019,
                yRotationDegrees: 87.2228,
                zRotationDegrees: -24.0868
            ),
            length: 0.04695
        )
    ]
)

let allFragmentGroups: [FragmentGroup] = [testingFibulaFragmentGroup, testFragmentGroup]
