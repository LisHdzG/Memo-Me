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
            // Si hay un espacio guardado, mostrar el TabView principal
            if spaceSelectionService.selectedSpace != nil {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                // Si no hay espacio guardado, mostrar la lista
                SpacesListView()
                    .environmentObject(authManager)
            }
        }
    }
}
