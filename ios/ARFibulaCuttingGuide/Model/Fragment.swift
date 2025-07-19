//
//  Fragment.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import Foundation
import simd

struct FragmentSlice: Identifiable {
    let id = UUID()
    var distanceFromLeftAnchor: Float
    var xRotationDegrees: Float
    var yRotationDegrees: Float
    var zRotationDegrees: Float
}

struct Fragment: Identifiable {
    var id = UUID()
    var startSlice: FragmentSlice
    var endSlice: FragmentSlice
    var length: Float
}

struct FragmentGroup: Identifiable {
    var id = UUID()
    var name: String
    var description: String
    var usdzModelName: String
    var fragments: [Fragment]
}
