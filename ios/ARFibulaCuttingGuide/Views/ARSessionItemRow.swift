//
//  ARSessionItemRow.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//


import SwiftUI
import RealityKit

struct ARSessionItemRow: View {
    var fragmentGroup: FragmentGroup
    
    var body: some View {
        HStack(spacing: 8) {
            Image("glyph")
                .resizable()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(fragmentGroup.name)
                Text(fragmentGroup.description)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
