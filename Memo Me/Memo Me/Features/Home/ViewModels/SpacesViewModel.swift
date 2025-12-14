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
    @Published var publicSpaces: [Space] = []
    @Published var userSpaces: [Space] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isJoiningSpace = false
    @Published var isJoiningPrivateSpace = false
    
    private let spaceService = SpaceService()
    
    func loadSpaces(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Cargar espacios públicos y espacios del usuario en paralelo
            async let publicSpacesTask = spaceService.getActiveSpaces(userId: userId)
            async let userSpacesTask = spaceService.getUserSpaces(userId: userId)
            
            publicSpaces = try await publicSpacesTask
            userSpaces = try await userSpacesTask
        } catch {
            errorMessage = "Error al cargar los espacios: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshSpaces(userId: String) async {
        await loadSpaces(userId: userId)
    }
    
    func isUserMember(space: Space, userId: String) -> Bool {
        return spaceService.isUserMember(space: space, userId: userId)
    }
    
    func joinSpace(space: Space, userId: String) async {
        isJoiningSpace = true
        errorMessage = nil
        
        do {
            try await spaceService.joinSpace(spaceId: space.spaceId, userId: userId)
            // Recargar los espacios después de unirse
            await loadSpaces(userId: userId)
        } catch {
            errorMessage = "Error al unirse al espacio: \(error.localizedDescription)"
        }
        
        isJoiningSpace = false
    }
    
    func joinSpaceByCode(code: String, userId: String) async -> Space? {
        isJoiningPrivateSpace = true
        errorMessage = nil
        
        do {
            // Unirse al espacio por código (funciona para públicos y privados)
            let joinedSpace = try await spaceService.joinSpaceByCode(code: code, userId: userId)
            
            // Recargar los espacios después de unirse
            await loadSpaces(userId: userId)
            
            isJoiningPrivateSpace = false
            return joinedSpace
        } catch {
            errorMessage = "Error al unirse al espacio: \(error.localizedDescription)"
            isJoiningPrivateSpace = false
            return nil
        }
    }
    
    // Mantener compatibilidad con código existente
    func joinPrivateSpace(code: String, userId: String) async -> Space? {
        return await joinSpaceByCode(code: code, userId: userId)
    }
}

