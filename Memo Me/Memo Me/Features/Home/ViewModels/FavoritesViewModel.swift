//
//  FavoritesViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import Combine

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favoriteContacts: [Contact] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    func loadFavoriteContacts() async {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.favoriteContacts = []
            self.isLoading = false
        }
    }
}

