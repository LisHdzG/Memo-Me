//
//  SpacesViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import Combine

@MainActor
class SpacesViewModel: ObservableObject {
    @Published var spaces: [Space] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let spaceService = SpaceService()
    
    func loadActiveSpaces(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            spaces = try await spaceService.getActiveSpaces(userId: userId)
        } catch {
            errorMessage = "Error al cargar los espacios: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshSpaces(userId: String) async {
        await loadActiveSpaces(userId: userId)
    }
}

