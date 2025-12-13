//
//  ContentView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var spaceSelectionService = SpaceSelectionService.shared
    
    var body: some View {
        Group {
            // Si hay un espacio guardado, ir directamente al detalle
            if let selectedSpace = spaceSelectionService.selectedSpace {
                NavigationView {
                    ContactDetailView(space: selectedSpace)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button(action: {
                                    spaceSelectionService.clearSelectedSpace()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.left")
                                        Text("Espacios")
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                        }
                }
            } else {
                // Si no hay espacio guardado, mostrar la lista
                SpacesListView()
                    .environmentObject(authManager)
            }
        }
    }
}
