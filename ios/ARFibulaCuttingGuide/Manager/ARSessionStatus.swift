//
//  ARSessionStatus.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import SwiftUI

enum SessionState: String {
    case initializing
    case coaching
    case searching
    case normal
    case limited
    case failed
    case tracking
    case locked
    case execution
}

@Observable
class ARSessionStatus {
    var current: SessionState = .initializing
}
