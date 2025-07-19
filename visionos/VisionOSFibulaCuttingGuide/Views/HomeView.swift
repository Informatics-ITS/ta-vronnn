//
//  HomeView.swift
//  VisionOSFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 05/05/25.
//

import SwiftUI
import ARKit
import RealityKit

struct HomeView: View {
    @Bindable var appState: AppState
    let immersiveSpaceIdentifier: String
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @State var selectedFragmentGroupId: UUID?
    @State private var searchText: String = ""
    
    var filteredFragmentGroups: [LoadedFragmentGroup] {
        if searchText.isEmpty {
            return appState.fragmentGroupLoader.loadedFragmentGroups
        } else {
            return appState.fragmentGroupLoader.loadedFragmentGroups.filter {
                $0.group.name.localizedCaseInsensitiveContains(searchText) ||
                $0.group.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        Group {
            if appState.canEnterImmersiveSpace {
                NavigationSplitView {
                    VStack {
                        List(selection: $selectedFragmentGroupId) {
                            ForEach(filteredFragmentGroups, id: \.id) { fragmentGroup in
                                HStack(spacing: 8) {
                                    Image("glyph")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                    
                                    VStack(alignment: .leading) {
                                        Text(fragmentGroup.group.name)
                                        Text(fragmentGroup.group.description)
                                            .lineLimit(1)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Session")
                        .searchable(text: $searchText, prompt: "Search groups")
                    }
                } detail: {
                    if let selectedObject = appState.fragmentGroupLoader.loadedFragmentGroups.first(where: { $0.id == selectedFragmentGroupId}) {
                        // Display the USDZ file that the reference object was displayed on in this detail view.
                        if let path = selectedObject.referenceObject.usdzFile {                            
                            Model3D(url: path) { model in
                                model
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(0.8) // try very small
                                    .offset(y: -50) // test offsetting
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Text("No preview available")
                        }

                    } else {
                        Text("No object selected")
                    }
                }
                .frame(minWidth: 400, minHeight: 300)
            }
        }
        .glassBackgroundEffect()
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                if appState.canEnterImmersiveSpace {
                    VStack {
                        if !appState.isImmersiveSpaceOpened {
                            if let selectedObject = appState.fragmentGroupLoader.loadedFragmentGroups.first(where: { $0.id == selectedFragmentGroupId}) {
                                Button("Start tracking") {
                                    appState.selectedFragmentGroup = selectedObject
                                    
                                    Task {
                                        switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                        case .opened:
                                            break
                                        case .error:
                                            print("An error occurred when trying to open the immersive space \(immersiveSpaceIdentifier)")
                                        case .userCancelled:
                                            print("The user declined opening immersive space \(immersiveSpaceIdentifier)")
                                        @unknown default:
                                            break
                                        }
                                    }
                                }
                                .disabled(!appState.canEnterImmersiveSpace)
                            }
                        } else {
                            Button("Stop tracking") {
                                Task {
                                    await dismissImmersiveSpace()
                                    appState.didLeaveImmersiveSpace()
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            // Ask for authorization before a person attempts to open the immersive space.
            // This gives the app opportunity to respond gracefully if authorization isn't granted.
            if appState.allRequiredProvidersAreSupported {
                await appState.requestWorldSensingAuthorization()
            }
        }
    }
}
