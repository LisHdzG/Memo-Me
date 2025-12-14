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
    @Published var favoriteContactsBySpace: [String: [FavoriteContact]] = [:]
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    private let favoriteService = FavoriteService()
    private let spaceService = SpaceService()
    private let userService = UserService()
    
    var allFavorites: [FavoriteContact] {
        favoriteContactsBySpace.values.flatMap { $0 }
    }
    
    var spaceNames: [String] {
        Array(favoriteContactsBySpace.keys).sorted()
    }
    
    func loadFavoriteContacts(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let favoritesData = try await favoriteService.getFavorites(userId: userId)
            
            guard !favoritesData.isEmpty else {
                favoriteContactsBySpace = [:]
                isLoading = false
                return
            }
            
            let spaceIds = favoritesData.compactMap { $0["spaceId"] as? String }
            let uniqueSpaceIds = Array(Set(spaceIds))
            
            var spacesMap: [String: Space] = [:]
            for spaceId in uniqueSpaceIds {
                if let space = try? await spaceService.getSpaceBySpaceId(spaceId) {
                    spacesMap[spaceId] = space
                }
            }
            
            var groupedFavorites: [String: [FavoriteContact]] = [:]
            
            for favoriteData in favoritesData {
                guard let contactUserId = favoriteData["contactUserId"] as? String,
                      let spaceId = favoriteData["spaceId"] as? String,
                      let space = spacesMap[spaceId] else {
                    continue
                }
                
                if let user = try? await userService.getUser(userId: contactUserId) {
                    let imageIndex = abs(contactUserId.hashValue) % 37 + 1
                    let imageNumber = String(format: "%02d", imageIndex)
                    
                    let contact = Contact(
                        id: UUID(uuidString: contactUserId) ?? UUID(),
                        name: user.name,
                        imageName: user.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                        imageUrl: user.photoUrl,
                        userId: contactUserId
                    )
                    
                    let favoriteContact = FavoriteContact(
                        id: favoriteData["id"] as? String ?? UUID().uuidString,
                        contact: contact,
                        spaceId: spaceId,
                        spaceName: space.name
                    )
                    
                    if groupedFavorites[space.name] == nil {
                        groupedFavorites[space.name] = []
                    }
                    groupedFavorites[space.name]?.append(favoriteContact)
                }
            }
            
            favoriteContactsBySpace = groupedFavorites
            isLoading = false
        } catch {
            errorMessage = "Error al cargar favoritos: \(error.localizedDescription)"
            favoriteContactsBySpace = [:]
            isLoading = false
        }
    }
}

