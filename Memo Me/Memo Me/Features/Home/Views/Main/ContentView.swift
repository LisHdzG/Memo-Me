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
            if spaceSelectionService.hasContinuedWithoutSpace || spaceSelectionService.selectedSpace != nil {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                SpacesListView()
                    .environmentObject(authManager)
            }
        }
    }
}
