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
            NavigationStack {
                ContactDetailView(space: spaceSelectionService.selectedSpace)
            }
            .tabItem {
                Label("Contacts", systemImage: "person.3.fill")
            }
            .tag(0)
            
            FavoritesView()
                .tabItem {
                    Label("Memos", systemImage: "star.fill")
                }
                .tag(1)
            
            ProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .accentColor(Color("DeepSpace"))
    }
}

