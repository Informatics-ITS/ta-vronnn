//
//  Orientation.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import simd

extension Float {
    var degreesToRadians: Float { self * .pi / 180 }
}

func quaternionFromEuler(xDeg: Float, yDeg: Float, zDeg: Float) -> simd_quatf {
    let x = simd_quatf(angle: xDeg.degreesToRadians, axis: [1, 0, 0])
    let y = simd_quatf(angle: yDeg.degreesToRadians, axis: [0, 1, 0])
    let z = simd_quatf(angle: zDeg.degreesToRadians, axis: [0, 0, 1])
    return z * y * x // match with data from blender
}

func extractEulerAngles(from quaternion: simd_quatf) -> (yaw: Float, pitch: Float, roll: Float) {
    let w = quaternion.vector.w
    let x = quaternion.vector.x
    let y = quaternion.vector.y
    let z = quaternion.vector.z
    
    // Convert quaternion to Euler angles
    let yaw = atan2(2.0 * (w * y + x * z), 1.0 - 2.0 * (y * y + x * x))
    let pitch = asin(2.0 * (w * x - y * z))
    let roll = atan2(2.0 * (w * z + x * y), 1.0 - 2.0 * (x * x + z * z))
    
    return (yaw, pitch, roll)
}

func translationMatrix(from translation: SIMD3<Float>) -> matrix_float4x4 {
    var matrix = matrix_identity_float4x4
    matrix.columns.3 = SIMD4<Float>(translation.x, translation.y, translation.z, 1.0)
    return matrix
}

// Helper function to create rotation matrix from quaternion
func rotationMatrix(from rotation: simd_quatf) -> matrix_float4x4 {
    let q = rotation
    let qx = q.imag.x
    let qy = q.imag.y
    let qz = q.imag.z
    let qw = q.real
    
    return matrix_float4x4(
        SIMD4<Float>(1 - 2*(qy*qy + qz*qz), 2*(qx*qy + qz*qw), 2*(qx*qz - qy*qw), 0),
        SIMD4<Float>(2*(qx*qy - qz*qw), 1 - 2*(qx*qx + qz*qz), 2*(qy*qz + qx*qw), 0),
        SIMD4<Float>(2*(qx*qz + qy*qw), 2*(qy*qz - qx*qw), 1 - 2*(qx*qx + qy*qy), 0),
        SIMD4<Float>(0, 0, 0, 1)
    )
}

extension simd_quatf {
    var eulerAngles: SIMD3<Float> {
        let w = self.real
        let x = self.imag.x
        let y = self.imag.y
        let z = self.imag.z
        
        // Roll (x-axis rotation)
        let sinr_cosp = 2 * (w * x + y * z)
        let cosr_cosp = 1 - 2 * (x * x + y * y)
        let roll = atan2(sinr_cosp, cosr_cosp)
        
        // Pitch (y-axis rotation)
        let sinp = 2 * (w * y - z * x)
        let pitch = abs(sinp) >= 1 ? copysign(.pi / 2, sinp) : asin(sinp)
        
        // Yaw (z-axis rotation)
        let siny_cosp = 2 * (w * z + x * y)
        let cosy_cosp = 1 - 2 * (y * y + z * z)
        let yaw = atan2(siny_cosp, cosy_cosp)
        
        return SIMD3<Float>(roll, pitch, yaw)
    }
    
    func act(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        let quat = self
        let quatVector = SIMD3<Float>(quat.imag.x, quat.imag.y, quat.imag.z)
        let quatScalar = quat.real
        
        let cross1 = cross(quatVector, vector)
        let cross2 = cross(quatVector, cross1)
        
        return vector + 2.0 * (quatScalar * cross1 + cross2)
    }
    
    init(_ eulerAngles: SIMD3<Float>) {
        let cx = cos(eulerAngles.x * 0.5)
        let sx = sin(eulerAngles.x * 0.5)
        let cy = cos(eulerAngles.y * 0.5)
        let sy = sin(eulerAngles.y * 0.5)
        let cz = cos(eulerAngles.z * 0.5)
        let sz = sin(eulerAngles.z * 0.5)
        
        let w = cx * cy * cz + sx * sy * sz
        let x = sx * cy * cz - cx * sy * sz
        let y = cx * sy * cz + sx * cy * sz
        let z = cx * cy * sz - sx * sy * cz
        
        self.init(ix: x, iy: y, iz: z, r: w)
    }
}
