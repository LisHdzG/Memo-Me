//
//  FavoriteService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import FirebaseFirestore

class FavoriteService {
    private let db = Firestore.firestore()
    private let favoritesCollection = "favorites"
    
    func getFavorites(userId: String) async throws -> [[String: Any]] {
        let querySnapshot = try await db.collection(favoritesCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        var favorites: [[String: Any]] = []
        for document in querySnapshot.documents {
            var data = document.data()
            data["id"] = document.documentID
            favorites.append(data)
        }
        
        return favorites
    }
    
    func getFavoriteSpaces(userId: String) async throws -> [String] {
        let favorites = try await getFavorites(userId: userId)
        let spaceIds = favorites.compactMap { $0["spaceId"] as? String }
        return Array(Set(spaceIds))
    }
}
