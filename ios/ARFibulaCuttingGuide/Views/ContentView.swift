//
//  ContentView.swift
//  ARFibulaCuttingGuide
//
//  Created by Mohammad Zhafran Dzaky on 29/04/25.
//

import SwiftUI

struct ContentView: View {
    @State var isPresented: Bool = false
    @State private var search = ""
    
    var body: some View {
        NavigationStack {
            List(filteredFragmentGroups) { fragmentGroup in
                NavigationLink {
                    ARSessionView(fragmentGroup: fragmentGroup)
                } label: {
                    ARSessionItemRow(fragmentGroup: fragmentGroup)
                }
            }
            .navigationTitle("Session")
            .searchable(text: $search)
        }
    }
    
    var filteredFragmentGroups: [FragmentGroup] {
        if search.isEmpty {
            return allFragmentGroups
        } else {
            return allFragmentGroups.filter { fragmentGroup in
                fragmentGroup.name.localizedCaseInsensitiveContains(search) ||
                fragmentGroup.description.localizedCaseInsensitiveContains(search)
            }
        }
    }
}

#Preview {
    ContentView()
}
