//
//  Extensions.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 18/05/25.
//

import RealityKit
import SwiftUI

extension Entity {
    static func createText(_ string: String, height: Float, color: UIColor = .white) -> ModelEntity {
        guard let font = MeshResource.Font(name: "Helvetica", size: CGFloat(height)) else {
            fatalError("Couldn't load font.")
        }
        
        let mesh = MeshResource.generateText(string, extrusionDepth: height * 0.05, font: font)
        let material = UnlitMaterial(color: color)
        let text = ModelEntity(mesh: mesh, materials: [material])
        return text
    }
    
    // create origin axis visualization
    static func createAxes(axisScale: Float, axisLength: Float = 1.0, alpha: CGFloat = 1.0) -> Entity {
        let axisEntity = Entity()
        let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])
        
        let xAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1).withAlphaComponent(alpha))])
        let yAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1).withAlphaComponent(alpha))])
        let zAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(alpha))])
        axisEntity.children.append(contentsOf: [xAxis, yAxis, zAxis])
        
        // axisMinorScale controls thickness
        let axisMinorScale = axisScale / 20
        
        // Scale determines the length of each axis
        let actualAxisLength = axisScale * axisLength
        
        // Position offset is half the length so one end of each axis is at origin
        let axisAxisOffset = actualAxisLength / 2.0
        
        xAxis.position = [axisAxisOffset, 0, 0]
        xAxis.scale = [actualAxisLength, axisMinorScale, axisMinorScale]
        
        yAxis.position = [0, axisAxisOffset, 0]
        yAxis.scale = [axisMinorScale, actualAxisLength, axisMinorScale]
        
        zAxis.position = [0, 0, axisAxisOffset]
        zAxis.scale = [axisMinorScale, axisMinorScale, actualAxisLength]
        
        return axisEntity
    }
    
    func applyMaterialRecursively(_ material: RealityFoundation.Material) {
        if let modelEntity = self as? ModelEntity {
            modelEntity.model?.materials = [material]
        }
        
        for child in children {
            child.applyMaterialRecursively(material)
        }
    }
}
