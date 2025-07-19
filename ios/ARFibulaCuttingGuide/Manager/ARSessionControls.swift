//
//  ARSessionControls.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import SwiftUI

@Observable
class ARSessionControls {
    var showMesh = false
    var showFeaturePoints = false
    var useOcclusion = true
    var opacity: Float = 0.4
    var resetSession = false
    var yOffset: Float = 0.08
    var isFragmentPlaced = true
    var xRotation: Float = 0.0
    var isGizmoEnabled: Bool = false
    var shouldResetSession: Bool = false
    var isPositionLocked: Bool = false
}
