//
//  FavoriteService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation

@MainActor
class FavoriteService {
    static let shared = FavoriteService()
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKeyPrefix = "favorites_space_"
    
    private init() {}
    
    // Obtener la clave para un espacio específico
    private func key(for spaceId: String?) -> String {
        guard let spaceId = spaceId, !spaceId.isEmpty else {
            return "favorites_no_space"
        }
        return "\(favoritesKeyPrefix)\(spaceId)"
    }
    
    // Obtener favoritos para un espacio
    func getFavorites(for spaceId: String?) -> [String] {
        let key = key(for: spaceId)
        return userDefaults.stringArray(forKey: key) ?? []
    }
    
    // Agregar un favorito
    func addFavorite(contactId: String, for spaceId: String?) {
        var favorites = getFavorites(for: spaceId)
        if !favorites.contains(contactId) {
            favorites.append(contactId)
            let key = key(for: spaceId)
            userDefaults.set(favorites, forKey: key)
        }
    }
    
    // Remover un favorito
    func removeFavorite(contactId: String, for spaceId: String?) {
        var favorites = getFavorites(for: spaceId)
        favorites.removeAll { $0 == contactId }
        let key = key(for: spaceId)
        userDefaults.set(favorites, forKey: key)
    }
    
    // Verificar si un contacto es favorito
    func isFavorite(contactId: String, for spaceId: String?) -> Bool {
        let favorites = getFavorites(for: spaceId)
        return favorites.contains(contactId)
    }
    
    // Toggle favorito (agregar si no está, remover si está)
    func toggleFavorite(contactId: String, for spaceId: String?) -> Bool {
        let isCurrentlyFavorite = isFavorite(contactId: contactId, for: spaceId)
        if isCurrentlyFavorite {
            removeFavorite(contactId: contactId, for: spaceId)
            return false
        } else {
            addFavorite(contactId: contactId, for: spaceId)
            return true
        }
    }
    
    // Obtener todos los favoritos (para migración o backup)
    func getAllFavorites() -> [String: [String]] {
        var result: [String: [String]] = [:]
        let defaults = userDefaults.dictionaryRepresentation()
        
        for (key, value) in defaults {
            if key.hasPrefix(favoritesKeyPrefix) {
                let spaceId = String(key.dropFirst(favoritesKeyPrefix.count))
                if let favorites = value as? [String] {
                    result[spaceId] = favorites
                }
            }
        }
        
        return result
    }
}
