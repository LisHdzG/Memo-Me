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
    
    private let favoriteService = FavoriteService.shared
    private let userService = UserService()
    private var usersMap: [String: User] = [:]
    var currentUserId: String?
    
    func loadFavoriteContacts(for space: Space?) async {
        isLoading = true
        errorMessage = nil
        
        guard let space = space else {
            favoriteContacts = []
            isLoading = false
            return
        }
        
        // Obtener IDs de favoritos para este espacio
        let favoriteIds = favoriteService.getFavorites(for: space.spaceId)
        
        guard !favoriteIds.isEmpty else {
            favoriteContacts = []
            isLoading = false
            return
        }
        
        do {
            // Cargar usuarios desde Firestore
            let users = try await userService.getUsers(userIds: favoriteIds)
            
            // Guardar usuarios en un mapa
            usersMap.removeAll()
            for user in users {
                if let userId = user.id {
                    usersMap[userId] = user
                }
            }
            
            // Filtrar el usuario actual de la lista
            let filteredUsers = users.filter { user in
                guard let userId = user.id, let currentUserId = currentUserId else {
                    return true
                }
                return userId != currentUserId
            }
            
            // Convertir usuarios a contactos, manteniendo solo los que están en favoritos
            favoriteContacts = filteredUsers.compactMap { user -> Contact? in
                guard let userId = user.id, favoriteIds.contains(userId) else {
                    return nil
                }
                
                let imageIndex = abs(user.id?.hashValue ?? 0) % 37 + 1
                let imageNumber = String(format: "%02d", imageIndex)
                
                return Contact(
                    id: UUID(uuidString: userId) ?? UUID(),
                    name: user.name,
                    imageName: user.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                    imageUrl: user.photoUrl,
                    userId: userId
                )
            }
            
            isLoading = false
        } catch {
            errorMessage = "Error al cargar favoritos: \(error.localizedDescription)"
            favoriteContacts = []
            isLoading = false
        }
    }
    
    func getUser(for contact: Contact) -> User? {
        guard let userId = contact.userId else { return nil }
        return usersMap[userId]
    }
    
    func refreshFavorites(for space: Space?) async {
        await loadFavoriteContacts(for: space)
    }
}

