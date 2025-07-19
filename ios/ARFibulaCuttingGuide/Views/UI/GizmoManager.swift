//
//  GizmoManager.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 18/05/25.
//

import ARKit
import RealityKit

class GizmoManager {
    private let arView: ARView
    private let fibula: ModelEntity
    private var controls: ARSessionControls
    
    private var verticalGizmoAnchor: AnchorEntity?
    private var rotationGizmoAnchor: AnchorEntity?
    private var verticalGizmo: ModelEntity?
    private var rotationGizmo: ModelEntity?
    
    private var initialTouchY: CGFloat = 0
    private var initialTouchX: CGFloat = 0
    private var initialVerticalPosition: Float = 0
    private var initialRotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    
    private var rotationPivotLocal: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    private var rotationPivotWorld: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    private var isGizmoActive: Bool = false
    private var activeGizmoType: GizmoType = .none
    
    private enum GizmoType {
        case none
        case vertical
        case rotation
    }
    
    init(arView: ARView, fibula: ModelEntity, controls: ARSessionControls) {
        self.arView = arView
        self.fibula = fibula
        self.controls = controls
    }
    
    func installGizmos() {
        // Create gizmos
        createVerticalGizmo()
        createRotationGizmo()
        
        // Add gesture recognizers
        addGestureRecognizers()
    }
    
    private func createVerticalGizmo() {
        verticalGizmoAnchor = AnchorEntity()
        arView.scene.addAnchor(verticalGizmoAnchor!)
        
        let coneMesh = MeshResource.generateCone(height: 0.01, radius: 0.005)
        let coneMaterial = UnlitMaterial(color: UIColor.systemGreen.withAlphaComponent(0.9))
        verticalGizmo = ModelEntity(mesh: coneMesh, materials: [coneMaterial])
        
        verticalGizmo?.generateCollisionShapes(recursive: true)
        
        verticalGizmoAnchor?.addChild(verticalGizmo!)
        
        updateVerticalGizmoPosition()
    }
    
    private func createRotationGizmo() {
        rotationGizmoAnchor = AnchorEntity()
        arView.scene.addAnchor(rotationGizmoAnchor!)
        
        rotationGizmo = ModelEntity()
        
        let bounds = fibula.visualBounds(relativeTo: fibula)
        let center = bounds.center
        
        let maxDimension = max(bounds.extents.y, bounds.extents.z)
        // Make sure the radius didnt get too big
        let radius: Float = maxDimension * 0.25
        
        rotationGizmo = ModelEntity()
        
        do {
            let gizmoModel = try Entity.loadModel(named: "fibula-ring-smaller")
            
            let gizmoModelEntity = ModelEntity()
            gizmoModel.scale = .one
            gizmoModelEntity.addChild(gizmoModel)
            
            // Scale the model to appropriate size based on fibula
            let gizmoScale: Float = radius / 0.5
            gizmoModelEntity.scale = SIMD3<Float>(repeating: gizmoScale)
            
            if var modelComponent = gizmoModelEntity.model {
                modelComponent.materials = [UnlitMaterial(color: UIColor.systemRed.withAlphaComponent(0.8))]
            }
            
            gizmoModelEntity.generateCollisionShapes(recursive: true)
            
            rotationGizmo?.addChild(gizmoModelEntity)
            
        } catch {
            print("Failed to load custom gizmo model: \(error.localizedDescription)")
            createFallbackRotationGizmo(radius: radius)
            return
        }
        
        let originVisualization = Entity.createAxes(axisScale: 0.05, axisLength: 0.7, alpha: 0.7)
        originVisualization.position = SIMD3<Float>(0, 0, 0)
        rotationGizmo?.addChild(originVisualization)
        
        rotationGizmo?.position = center
        
        rotationGizmoAnchor?.addChild(rotationGizmo!)
        
        updateRotationGizmoPosition()
    }

    private func createFallbackRotationGizmo(radius: Float) {
        let segmentCount = 32
        let material = UnlitMaterial(color: UIColor.systemRed.withAlphaComponent(0.8))
        let cylinderRadius: Float = 0.002
        
        for i in 0..<segmentCount {
            let angle = Float(i) * (2.0 * .pi / Float(segmentCount))
            let nextAngle = Float(i + 1) * (2.0 * .pi / Float(segmentCount))
            
            // Points on the circle
            let y1 = radius * sin(angle)
            let z1 = radius * cos(angle)
            let y2 = radius * sin(nextAngle)
            let z2 = radius * cos(nextAngle)
            
            // Calculate length and orientation
            let dy = y2 - y1
            let dz = z2 - z1
            let length = sqrt(dy * dy + dz * dz)
            
            // Create cylinder segment
            let cylinder = MeshResource.generateCylinder(height: length, radius: cylinderRadius)
            let segment = ModelEntity(mesh: cylinder, materials: [material])
            
            // Position and orient the cylinder
            segment.position = [0, y1 + dy/2, z1 + dz/2]
            
            // Calculate rotation to orient the segment properly
            let segmentAngle = atan2(dz, dy)
            segment.transform.rotation = simd_quatf(angle: segmentAngle - .pi/2, axis: [1, 0, 0])
            
            rotationGizmo?.addChild(segment)
        }
        
        // Add direction indicators using cones
        for angle in stride(from: 0, to: Float.pi * 2, by: Float.pi/2) {
            let arrowMesh = MeshResource.generateCone(height: 0.015, radius: 0.005)
            let arrowEntity = ModelEntity(mesh: arrowMesh, materials: [material])
            
            // Position on the circle
            arrowEntity.position = [0, radius * sin(angle), radius * cos(angle)]
            
            // Orient tangent to the circle
            let arrowRotation = simd_quatf(angle: angle + Float.pi/2, axis: [1, 0, 0])
            arrowEntity.transform.rotation = arrowRotation
            
            rotationGizmo?.addChild(arrowEntity)
        }
        
        // Add collision component using multiple cylinders for the ring
        for i in 0..<8 {
            let angle = Float(i) * (.pi / 4.0)
            let nextAngle = Float(i + 1) * (.pi / 4.0)
            
            // Create thicker collision cylinders around the circle
            let collisionCylinder = MeshResource.generateCylinder(
                height: radius * 0.8,  // Length of arc segment
                radius: 0.01           // Thicker for easier interaction
            )
            
            let collisionEntity = ModelEntity(
                mesh: collisionCylinder,
                materials: [SimpleMaterial(color: .clear, isMetallic: false)]
            )
            
            // Position at appropriate segment of the circle
            let midAngle = (angle + nextAngle) / 2
            collisionEntity.position = [0, radius * sin(midAngle), radius * cos(midAngle)]
            
            // Orient along the circle
            let orientation = atan2(cos(midAngle), sin(midAngle))
            collisionEntity.transform.rotation = simd_quatf(angle: orientation, axis: [1, 0, 0])
            
            // Generate collision shape
            collisionEntity.generateCollisionShapes(recursive: false)
            rotationGizmo?.addChild(collisionEntity)
        }
    }
    
    private func addGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        arView.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: arView)
        
        switch gesture.state {
        case .began:
            if let hitEntity = arView.entity(at: location) {
                // Check for vertical gizmo
                if isEntityOrChild(hitEntity, equalTo: verticalGizmo) {
                    initialTouchX = location.x
                    initialVerticalPosition = fibula.position.y
                    isGizmoActive = true
                    activeGizmoType = .vertical
                    print("Vertical gizmo selected")
                }
                // Check for rotation gizmo
                else if isEntityOrChild(hitEntity, equalTo: rotationGizmo) {
                    initialTouchX = location.x
                    initialRotation = fibula.transform.rotation
                    
                    // Calculate and store the fixed pivot point (visual center at start of gesture)
                    rotationPivotLocal = fibula.visualBounds(relativeTo: fibula).center
                    rotationPivotWorld = fibula.convert(position: rotationPivotLocal, to: nil)
                    
                    isGizmoActive = true
                    activeGizmoType = .rotation
                    print("Rotation gizmo selected")
                }
            }
        case .changed:
            if isGizmoActive {
                switch activeGizmoType {
                case .vertical:
                    let currentX = location.x
                    let deltaX = Float(currentX - initialTouchX)
                    
                    let verticalMovementSensitivity: Float = 0.0005
                    let deltaYOffset = deltaX * verticalMovementSensitivity
                    
                    fibula.position.y = initialVerticalPosition + deltaYOffset
                    
                    updateVerticalGizmoPosition()
                    
                    print("Vertical gizmo moved: \(fibula.position.y)")
                    
                case .rotation:
                    let currentX = location.x
                    let deltaX = Float(currentX - initialTouchX) * (-0.01)
                    
                    // Use the initial rotation matrix for consistent axis calculation
                    let initialMatrix = matrix_float4x4(initialRotation)
                    let xAxis = SIMD3<Float>(initialMatrix.columns.0.x, initialMatrix.columns.0.y, initialMatrix.columns.0.z)
                    let xRotationDelta = simd_quatf(angle: deltaX, axis: normalize(xAxis))
                    
                    // Apply the rotation
                    fibula.transform.rotation = xRotationDelta * initialRotation
                    
                    // Calculate where the fixed pivot point is now after rotation
                    let currentPivotWorld = fibula.convert(position: rotationPivotLocal, to: nil)
                    
                    // Adjust position to keep the fixed pivot point at its original world position
                    let correction = rotationPivotWorld - currentPivotWorld
                    fibula.position += correction
                    
                case .none:
                    break
                }
            }
        case .ended, .cancelled:
            initialTouchY = 0
            initialTouchX = 0
            isGizmoActive = false
            activeGizmoType = .none
        default:
            break
        }
    }
    
    func updateRotationGizmoPosition() {
        guard let rotationGizmo, let rotationGizmoAnchor else { return }

        let fibulaTransform = fibula.transformMatrix(relativeTo: nil)

        rotationGizmoAnchor.transform.matrix = fibulaTransform

        let localCenter = fibula.visualBounds(relativeTo: fibula).center
        rotationGizmo.position = localCenter
    }
    
    func updateVerticalGizmoPosition() {
        guard let verticalGizmo else { return }
        
        let bounds = fibula.visualBounds(relativeTo: nil)
        
        let worldPosition = bounds.center + SIMD3<Float>(0, 0.05, 0)
        
        verticalGizmo.position = worldPosition
    }
    
    private func isEntityOrChild(_ entity: Entity, equalTo targetEntity: ModelEntity?) -> Bool {
        guard let target = targetEntity else { return false }
        
        if entity.id == target.id {
            return true
        }
        
        var currentEntity: Entity? = entity
        while let parent = currentEntity?.parent {
            if parent.id == target.id {
                return true
            }
            currentEntity = parent
        }
        
        return false
    }
    
    func removeGizmos() {
        verticalGizmoAnchor?.removeFromParent()
        rotationGizmoAnchor?.removeFromParent()
    }

    func toggleGizmos(isVisible: Bool) {
        [verticalGizmo, rotationGizmo].forEach { gizmo in
            guard let gizmo = gizmo else { return }
            
            if isVisible {
                gizmo.isEnabled = true
                gizmo.components.remove(OpacityComponent.self)
                updateRotationGizmoPosition()
                updateVerticalGizmoPosition()
            } else {
                gizmo.isEnabled = false
                gizmo.components.set(OpacityComponent(opacity: 0))
            }
        }
    }
}
