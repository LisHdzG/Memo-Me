//
//  MainTabView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContactDetailView(space: spaceSelectionService.selectedSpace)
                .tabItem {
                    Label("Contactos", systemImage: "person.3.fill")
                }
                .tag(0)
            
            // Tab 2: Favoritos
            FavoritesView()
                .tabItem {
                    Label("Favoritos", systemImage: "heart.fill")
                }
                .tag(1)
            
            // Tab 3: Perfil
            ProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Perfil", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .accentColor(Color("PurpleGradientTop"))
    }
}

