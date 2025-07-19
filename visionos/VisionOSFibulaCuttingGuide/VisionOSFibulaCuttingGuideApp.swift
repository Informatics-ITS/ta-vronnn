//
//  VisionOSFibulaCuttingGuideApp.swift
//  VisionOSFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 05/05/25.
//

import SwiftUI

private enum UIIdentifier {
    static let immersiveSpace = "Object tracking"
}

@main
struct VisionOSFibulaCuttingGuideApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            HomeView(appState: appState, immersiveSpaceIdentifier: UIIdentifier.immersiveSpace)
                .task {
                    if appState.allRequiredProvidersAreSupported {
                        await appState.fragmentGroupLoader.loadFragmentGroups(allFragmentGroups)
                    }
                }
        }
        
        ImmersiveSpace(id: UIIdentifier.immersiveSpace) {
            ObjectTrackingView(appState: appState)
        }
    }
}
