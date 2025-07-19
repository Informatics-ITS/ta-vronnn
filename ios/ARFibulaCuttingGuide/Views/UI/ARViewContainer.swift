//
//  ARViewContainer.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import SwiftUI
import ARKit
import RealityKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    var fragmentGroup: FragmentGroup
    var controls: ARSessionControls
    var status: ARSessionStatus
    
    func setupWorldTrackingConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        
        // load reference object (the anchor)
        if let referenceObjects = loadReferenceObjects() {
            configuration.detectionObjects = referenceObjects
        }
        
        // improve depth with LiDAR
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
            configuration.frameSemantics.insert(.smoothedSceneDepth)
        }
        
        return configuration
    }
    
    func setupCoachingOverlay(arView: ARView, context: Context) -> ARCoachingOverlayView {
        // Add coaching overlay to detect horizontal plane faster (for interaction)
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.delegate = context.coordinator
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return coachingOverlay
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        arView.session.delegate = context.coordinator
        
        let configuration = setupWorldTrackingConfiguration()
        
        // improve interaction precision with LiDAR
        arView.environment.sceneUnderstanding.options.insert(
            [.occlusion, .physics, .collision, .receivesLighting]
        )
        
        // run session
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // add coaching overlay
        let coachingOverlay = setupCoachingOverlay(arView: arView, context: context)
        
        // add coaching overlay to the view
        arView.addSubview(coachingOverlay)
        
        // pass necessary props to the coordinator
        context.coordinator.coachingOverlay = coachingOverlay
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Trigger for toggling gizmo visibility and interaction
        context.coordinator.gizmoManager?.toggleGizmos(isVisible: controls.isGizmoEnabled)
        
        // Trigger for ONE-TIME locking position (only when not already locked)
        if controls.isPositionLocked && !context.coordinator.isPositionLocked {
            context.coordinator.lockPosition()
        }
        
        // Trigger for update state for placing fragment
        if !controls.isFragmentPlaced {
            context.coordinator.placeFragments()
            controls.isFragmentPlaced = true
        }
        
        // Trigger for reset session
        if controls.shouldResetSession {
            context.coordinator.resetSession()
            controls.shouldResetSession = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func loadReferenceObjects() -> Set<ARReferenceObject>? {
        guard let referenceObjects = ARReferenceObject.referenceObjects(inGroupNamed: "ruang-hijau-giga", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        return referenceObjects
    }
    
    class Coordinator: NSObject, ARSessionDelegate, ARCoachingOverlayViewDelegate {
        var parent: ARViewContainer
        
        var arView: ARView?
        var coachingOverlay: ARCoachingOverlayView?
        
        var objectAnchor: ARObjectAnchor?
        var trackingAnchor: AnchorEntity?  // Anchor that follows the tracked object
        var lockedAnchor: AnchorEntity?   // Fixed anchor when position is locked
        var fibula: ModelEntity?
        var fibulaModel: Entity?   // For later opacity manipulation
        
        var anchorIsFound: Bool = false
        var isPositionLocked: Bool = false
        
        var gizmoManager: GizmoManager?
        
        var sceneUpdateCancellable: Cancellable?
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        func setupGizmos() {
            guard let fibula, let arView else { return }
            
            let gizmoManager = GizmoManager(arView: arView, fibula: fibula, controls: parent.controls)
            gizmoManager.installGizmos()
            gizmoManager.toggleGizmos(isVisible: false)
            
            // Store reference to gizmo manager
            self.gizmoManager = gizmoManager
        }
        
        private func startTrackingGizmos() {
            sceneUpdateCancellable = arView?.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                guard let self = self, self.isPositionLocked else { return }
                self.gizmoManager?.updateVerticalGizmoPosition()
                self.gizmoManager?.updateRotationGizmoPosition()
            }
        }

        private func stopTrackingGizmos() {
            sceneUpdateCancellable?.cancel()
            sceneUpdateCancellable = nil
        }
        
        func lockPosition() {
            guard let arView, let fibula, !isPositionLocked else { return }
            
            // Get current world transform
            let currentWorldTransform = fibula.transformMatrix(relativeTo: nil)
            
            // Extract and constrain rotation - keep Z rotation at 0 (upright)
            let currentRotation = Transform(matrix: currentWorldTransform).rotation
            let constrainedRotation = constrainZAxisRotation(currentRotation)
            
            // Create new transform with constrained rotation
            let constrainedTransform = matrix_multiply(
                translationMatrix(from: Transform(matrix: currentWorldTransform).translation),
                rotationMatrix(from: constrainedRotation)
            )
            
            // Create locked anchor at the current world position
            let lockedAnchor = AnchorEntity(world: constrainedTransform)
            
            // Remove fibula from tracking anchor and reset its local transform
            fibula.removeFromParent()
            fibula.transform = Transform.identity
            lockedAnchor.addChild(fibula)
            
            // Add locked anchor to scene
            arView.scene.addAnchor(lockedAnchor)
            
            // Store reference and clean up tracking anchor
            self.lockedAnchor = lockedAnchor
            trackingAnchor?.removeFromParent()
            trackingAnchor = nil
            
            // Enable gestures and gizmos for interaction
            arView.installGestures([.translation, .rotation], for: fibula)
            
            // Update state
            self.isPositionLocked = true
            
            // Start gizmo tracking
            gizmoManager?.updateRotationGizmoPosition()
            startTrackingGizmos()
            
            parent.status.current = .locked
            
            print("Position locked successfully - no more tracking")
        }
        
        private func constrainZAxisRotation(_ rotation: simd_quatf) -> simd_quatf {
            // Convert quaternion to euler angles
            let euler = rotation.eulerAngles
            
            // Keep X and Y rotations, set Z rotation to 0 (upright)
            let constrainedEuler = SIMD3<Float>(euler.x, euler.y, 0)
            
            // Convert back to quaternion
            return simd_quatf(constrainedEuler)
        }
        
        func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
            print("Coaching overlay will activate")
            parent.status.current = .coaching
        }
        
        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            print("Coaching overlay did deactivate")
            parent.status.current = .searching
        }
        
        func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
            print("Coaching requested session reset")
            resetSession()
        }
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            switch camera.trackingState {
            case .notAvailable:
                parent.status.current = .failed
            case .limited(let reason):
                parent.status.current = .limited
                print(reason)
            case .normal:
                if !anchorIsFound {
                    parent.status.current = .searching
                } else if !isPositionLocked {
                    parent.status.current = .tracking
                }
            }
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let objectAnchor = anchor as? ARObjectAnchor {
                    self.objectAnchor = objectAnchor
                    anchorIsFound = true
                    parent.status.current = .tracking
                    placeTrackingModel(objectAnchor: objectAnchor)
                }
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let objectAnchor = anchor as? ARObjectAnchor,
                   objectAnchor.identifier == self.objectAnchor?.identifier,
                   !isPositionLocked {  // Only update if not locked
                    
                    // Ensure fibula Z rotation stays at 0 on tracking mode
                    if let fibula {
                        let currentRotation = fibula.orientation
                        let constrainedRotation = constrainZAxisRotation(currentRotation)
                        fibula.orientation = constrainedRotation
                    }
                    
                    print("Object anchor updated - tracking with Z constraint")
                }
            }
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                if let objectAnchor = anchor as? ARObjectAnchor,
                   objectAnchor.identifier == self.objectAnchor?.identifier {
                    self.objectAnchor = nil
                    if !isPositionLocked {  // Only reset if not locked
                        resetSession()
                    }
                    print("Object anchor removed")
                }
            }
        }
        
        func createAnchorBoundingBox(extent: simd_float3, anchor: AnchorEntity) {
            let boxMesh = MeshResource.generateBox(size: extent)
            let boxMaterial = SimpleMaterial(color: .systemBlue.withAlphaComponent(0.2), isMetallic: false)
            let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
            
            boxEntity.position = [0, extent.y / 2, 0]
            
            anchor.addChild(boxEntity)
        }
        
        private func triggerObjectDetectionHaptic() {
            // Notification haptic for object detection success
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            // Subtle impact for additional tactile confirmation
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        func placeTrackingModel(objectAnchor: ARObjectAnchor) {
            guard let arView else { return }
            
            // Create tracking anchor that follows the detected object
            let trackingAnchor = AnchorEntity(anchor: objectAnchor)
            
            guard let fibulaEntity = try? Entity.load(named: parent.fragmentGroup.usdzModelName) else {
                fatalError("Failed to load USDZ model")
            }
            
            fibulaEntity.name = parent.fragmentGroup.usdzModelName
            fibulaEntity.components.set(OpacityComponent(opacity: 0.95))
            fibulaModel = fibulaEntity
            
            let fibulaModelEntity = ModelEntity()
            fibulaModelEntity.addChild(fibulaEntity)
            fibulaModelEntity.generateCollisionShapes(recursive: true)
            
            let bounds = fibulaModelEntity.visualBounds(relativeTo: nil)
            let center = bounds.center
            let extents = bounds.extents
            
            // Create visual indicators (dots and line)
            let dotOffset: Float = 0.005  // 5mm
            let dotRadius: Float = 0.003  // 3mm
            
            let leftDotPos = SIMD3<Float>(
                center.x - extents.x / 2 - dotOffset,
                center.y,
                center.z
            )
            let rightDotPos = SIMD3<Float>(
                center.x + extents.x / 2 + dotOffset,
                center.y,
                center.z
            )
            
            let dotMaterial = UnlitMaterial(color: .white.withAlphaComponent(0.8))

            // Create and place dots
            let leftDot = ModelEntity(mesh: .generateSphere(radius: dotRadius), materials: [dotMaterial])
            leftDot.position = leftDotPos

            let rightDot = ModelEntity(mesh: .generateSphere(radius: dotRadius), materials: [dotMaterial])
            rightDot.position = rightDotPos

            // Line connecting dots
            let lineLength = distance(leftDotPos, rightDotPos)
            let lineThickness: Float = 0.001
            let lineMesh = MeshResource.generateBox(size: [lineLength, lineThickness, lineThickness])
            let lineMaterial = UnlitMaterial(color: .white.withAlphaComponent(0.5))
            let line = ModelEntity(mesh: lineMesh, materials: [lineMaterial])
            
            line.position = (leftDotPos + rightDotPos) / 2
            line.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])
            
            let anchorBounds = trackingAnchor.visualBounds(relativeTo: nil)
            let anchorTopY = anchorBounds.center.y + anchorBounds.extents.y
            let fibulaBottomY = bounds.center.y - bounds.extents.y
            let yOffset = anchorTopY - fibulaBottomY - 0.01 // adjustable constant
            
            fibulaModelEntity.position.y += yOffset
            
            // Fix: Position origin visualization at the fibula's actual center
            let originVisualization = Entity.createAxes(axisScale: 0.05, axisLength: 0.5, alpha: 0.7)
            let finalBounds = fibulaModelEntity.visualBounds(relativeTo: fibulaModelEntity)
            originVisualization.position = finalBounds.center

            // Add visual indicators to fibulaModelEntity
            fibulaModelEntity.addChild(leftDot)
            fibulaModelEntity.addChild(rightDot)
            fibulaModelEntity.addChild(line)
            fibulaModelEntity.addChild(originVisualization)
            
            trackingAnchor.addChild(fibulaModelEntity)
            arView.scene.addAnchor(trackingAnchor)
            
            // Store references
            self.trackingAnchor = trackingAnchor
            self.fibula = fibulaModelEntity
            
            // Trigger haptic
            triggerObjectDetectionHaptic()
            
            setupGizmos()
            
            coachingOverlay?.setActive(false, animated: true)
        }
        
        func placeFragments() {
            guard let fibula, let fibulaModel, !parent.controls.isFragmentPlaced else { return }
            
            // Set opacity lower for execution
            fibulaModel.components.set(OpacityComponent(opacity: 0.7))
            
            let bounds = fibula.visualBounds(relativeTo: fibula)
            let localLeftAnchor = bounds.center - SIMD3(bounds.extents.x / 2, 0, 0)
            let direction = normalize(SIMD3<Float>(1, 0, 0))
            
            for (index, fragment) in parent.fragmentGroup.fragments.enumerated() {
                let color = fragmentColors[index % fragmentColors.count]
                
                for slice in [fragment.startSlice, fragment.endSlice] {
                    let entity = createFragmentSlice(color: color)
                    
                    let offset = direction * slice.distanceFromLeftAnchor
                    entity.position = localLeftAnchor + offset
                    
                    let eulerRotation = quaternionFromEuler(
                        xDeg: slice.xRotationDegrees,
                        yDeg: slice.yRotationDegrees,
                        zDeg: slice.zRotationDegrees
                    )
                    
                    entity.orientation = eulerRotation
                    
                    fibula.addChild(entity)
                }
            }
            
            gizmoManager?.toggleGizmos(isVisible: false)
            
            parent.controls.isFragmentPlaced = true
            parent.status.current = .execution
        }
        
        func createFragmentSlice(color: SimpleMaterial.Color) -> Entity {
            let width: Float = 0.035
            let height: Float = 0.035
            let depth: Float = 0.0005
            
            let mesh = MeshResource.generateBox(width: width, height: height, depth: depth)
            let material = SimpleMaterial(color: color, roughness: 0.5, isMetallic: false)
            let model = ModelEntity(mesh: mesh, materials: [material])
            
            let slice = Entity()
            slice.addChild(model)
            
            return slice
        }
        
        func resetSession() {
            guard let arView else { return }
            
            anchorIsFound = false
            isPositionLocked = false
            parent.controls.isPositionLocked = false
            
            // Remove fibula
            fibula?.removeFromParent()
            fibula = nil
            
            // Clean up anchors
            trackingAnchor?.removeFromParent()
            trackingAnchor = nil
            lockedAnchor?.removeFromParent()
            lockedAnchor = nil
            
            // Remove scene update frame subscription
            sceneUpdateCancellable?.cancel()
            sceneUpdateCancellable = nil
            
            // Reset gizmo manager
            gizmoManager = nil
            
            let configuration = parent.setupWorldTrackingConfiguration()
            
            arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
            coachingOverlay?.setActive(true, animated: true)
        }
    }
}
