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
    private var currentUserId: String?
    private let encoder = JSONEncoder()
    
    func loadSpaces(userId: String) async {
        currentUserId = userId
        
        isLoading = true
        errorMessage = nil
        
        do {
            async let publicSpacesTask = spaceService.getActiveSpaces(userId: userId)
            async let userSpacesTask = spaceService.getUserSpaces(userId: userId)
            
            publicSpaces = try await publicSpacesTask
            userSpaces = try await userSpacesTask
            
            startListeningToSpaces(userId: userId)
        } catch {
            errorMessage = "Error al cargar los espacios: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func startListeningToSpaces(userId: String) {
        stopListeningToSpaces()
        
        spaceService.listenToAllSpaces(
            userId: userId,
            onPublicSpacesUpdate: { [weak self] spaces in
                Task { @MainActor in
                    self?.updatePublicSpacesIfNeeded(spaces)
                }
            },
            onUserSpacesUpdate: { [weak self] spaces in
                Task { @MainActor in
                    self?.updateUserSpacesIfNeeded(spaces)
                }
            }
        )
    }
    
    func stopListeningToSpaces() {
        spaceService.stopListeningToAllSpaces()
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
            let joinedSpace = try await spaceService.joinSpaceByCode(code: code, userId: userId)
            
            await loadSpaces(userId: userId)
            
            isJoiningPrivateSpace = false
            return joinedSpace
        } catch {
            errorMessage = "Error al unirse al espacio: \(error.localizedDescription)"
            isJoiningPrivateSpace = false
            return nil
        }
    }
    
    private func updatePublicSpacesIfNeeded(_ spaces: [Space]) {
        guard spacesChanged(newSpaces: spaces, currentSpaces: publicSpaces) else { return }
        publicSpaces = spaces
    }
    
    private func updateUserSpacesIfNeeded(_ spaces: [Space]) {
        guard spacesChanged(newSpaces: spaces, currentSpaces: userSpaces) else { return }
        userSpaces = spaces
    }
    
    private func spacesChanged(newSpaces: [Space], currentSpaces: [Space]) -> Bool {
        guard let newData = try? encoder.encode(newSpaces),
              let currentData = try? encoder.encode(currentSpaces) else { return true }
        return newData != currentData
    }
}

