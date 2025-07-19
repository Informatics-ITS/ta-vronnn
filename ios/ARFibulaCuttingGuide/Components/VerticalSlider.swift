//
//  VerticalSlider.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import SwiftUI

struct VerticalSlider: View {
    @Binding var value: Float
    var range: ClosedRange<Float> = 0...0.25
    var step: Float = 0.00025

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let normalized = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let knobY = height * (1 - normalized)

            ZStack(alignment: .top) {
                // Track background (unfilled)
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 10)
                
                // Track fill (from bottom to knob)
                VStack {
                    Spacer()
                    Capsule()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 10, height: height * normalized)
                }

                // Draggable knob
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 28, height: 28)
                    .shadow(radius: 1.5)
                    .offset(y: knobY - 14)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let y = gesture.location.y
                                let clampedY = min(max(y, 0), height)
                                let newValue = Float(1 - clampedY / height) * (range.upperBound - range.lowerBound) + range.lowerBound
                                value = (newValue / step).rounded() * step
                            }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 48)
        .padding(.vertical, 40)
        .accessibilityElement()
        .accessibilityLabel("Adjustment slider")
        .accessibilityValue(String(format: "%.2f", value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(value + step, range.upperBound)
            case .decrement:
                value = max(value - step, range.lowerBound)
            default: break
            }
        }
    }
}
