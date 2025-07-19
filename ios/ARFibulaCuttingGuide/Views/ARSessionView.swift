//
//  ARSessionView.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import SwiftUI

struct ARSessionView: View {
    var fragmentGroup: FragmentGroup
    
    @Environment(\.dismiss) private var dismiss
    
    @State var controls = ARSessionControls()
    @State var status = ARSessionStatus()
    
    @State var isManualShown: Bool = false
    
    private var instructionText: String {
        switch status.current {
        case .searching:
            return "Move the camera around to find the fibula. Once found, it will be detected automatically."
        case .tracking:
            return "Great! Fibula detected and tracking. When you're satisfied with the alignment, tap the lock button to secure the position for fine adjustments."
        case .locked:
            return "Adjust the fibula model position in the scene. Use the gizmo controls for fine rotation or translation. Press Apply when done."
        case .execution:
            return "Happy cutting!, and do more adjustment if needed."
        default:
            return "Getting things ready..."
        }
    }
    
    private var stateDisplayText: String {
        switch status.current {
        case .initializing:
            return "Starting Up"
        case .coaching:
            return "Setup Guide"
        case .searching:
            return "Finding Fibula"
        case .normal:
            return "Ready"
        case .limited:
            return "Limited Tracking"
        case .failed:
            return "Connection Lost"
        case .tracking:
            return "Tracking Active"
        case .locked:
            return "Position Locked"
        case .execution:
            return "Surgery Mode"
        }
    }
    
    private func isStepCompleted(_ step: SessionState) -> Bool {
        switch (step, status.current) {
        case (.searching, .tracking), (.searching, .locked), (.searching, .execution):
            return true
        case (.tracking, .locked), (.tracking, .execution):
            return true
        case (.locked, .execution):
            return true
        default:
            return false
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ARViewContainer(
                fragmentGroup: fragmentGroup,
                controls: controls,
                status: status
            )
            .ignoresSafeArea(.all)
            
            HStack {
                Button {
                    controls.shouldResetSession = true
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
                Spacer()
                
                Button {
                    controls.isPositionLocked = true
                } label: {
                    Image(systemName: controls.isPositionLocked ? "lock.fill" : "lock.open")
                        .font(.title)
                        .foregroundStyle(controls.isPositionLocked ? Color.indigo : Color.white)
                        .shadow(radius: 2)
                }
                .disabled(controls.isPositionLocked)
                .opacity(controls.isPositionLocked ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: controls.isPositionLocked)
                .sensoryFeedback(.impact, trigger: controls.isPositionLocked)
                
                Spacer()

                Button {
                    controls.shouldResetSession = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .sensoryFeedback(.impact, trigger: controls.shouldResetSession)
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
            
            VStack {
                HStack {
                    Spacer()
                    
                    Text(stateDisplayText)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: 240, alignment: .center)
                    
                    Spacer()
                }
            }
            .padding(.top, 96)
            
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    if isManualShown {
                        VStack(alignment: .leading, spacing: 16) {
                            // Progressive marker - 4 states
                            HStack(spacing: 6) {
                                // Step 1: Searching
                                Circle()
                                    .fill(status.current == .searching ? .indigo : (isStepCompleted(.searching) ? .white : .gray))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(status.current == .searching ? 1.3 : 1.0)
                                
                                // Step 2: Tracking
                                Circle()
                                    .fill(status.current == .tracking ? .indigo : (isStepCompleted(.tracking) ? .white : .gray))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(status.current == .tracking ? 1.3 : 1.0)
                                
                                // Step 3: Locked (Adjustment)
                                Circle()
                                    .fill(status.current == .locked ? .indigo : (isStepCompleted(.locked) ? .white : .gray))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(status.current == .locked ? 1.3 : 1.0)
                                
                                // Step 4: Execution
                                Circle()
                                    .fill(status.current == .execution ? .indigo : (isStepCompleted(.execution) ? .white : .gray))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(status.current == .execution ? 1.3 : 1.0)
                            }
                            .animation(.easeInOut(duration: 0.3), value: status.current)
                            
                            Text(instructionText)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(24)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.black).opacity(0.85))
                                        .shadow(radius: 8)
                                )
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.scale(scale: 0.95, anchor: .bottom).combined(with: .opacity))
                        }
                        .transition(.scale(scale: 0.95, anchor: .bottom).combined(with: .opacity))
                    }
                }
                .padding(28)
                .animation(.easeInOut(duration: 0.3), value: isManualShown)
                .animation(.easeInOut(duration: 0.3), value: status.current)
                
                HStack {
                    VStack(spacing: 4) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isManualShown.toggle()
                            }
                        } label: {
                            Image(systemName: isManualShown ? "xmark" : "questionmark")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(.darkGray))
                                .padding()
                                .background(.white)
                                .clipShape(Circle())
                        }
                        .shadow(radius: 6)
                        .sensoryFeedback(.impact, trigger: isManualShown)
                        
                        Text("Help")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        controls.isFragmentPlaced = false
                    } label: {
                        Text("APPLY")
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(24)
                            .background([.locked].contains(status.current) ? Color.indigo : Color.indigo.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    .shadow(radius: 3)
                    .disabled(![.locked].contains(status.current))
                    .padding(.bottom, 28)
                    .sensoryFeedback(.impact, trigger: controls.isFragmentPlaced)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Button {
                            controls.isGizmoEnabled.toggle()
                        } label: {
                            Image(systemName: "move.3d")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding()
                                .background([.locked].contains(status.current) ? Color.indigo : Color.indigo.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .shadow(radius: 6)
                        .disabled(![.locked].contains(status.current))
                        .sensoryFeedback(.impact, trigger: controls.isGizmoEnabled)
                        
                        Text("Controls")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 14)
            }
        }
        .toolbar(.hidden)
    }
}
