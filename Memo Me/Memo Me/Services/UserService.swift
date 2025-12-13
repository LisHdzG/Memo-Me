//
//  UserService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class UserService: ObservableObject {
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    func checkUserExists(appleId: String) async throws -> User? {
        let querySnapshot = try await db.collection(usersCollection)
            .whereField("appleId", isEqualTo: appleId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            return nil
        }
        
        var user = try document.data(as: User.self)
        user.id = document.documentID
        return user
    }
    
    func createUser(_ user: User) async throws -> String {
        let docRef = try await db.collection(usersCollection).addDocument(from: user)
        return docRef.documentID
    }
    
    func updateUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "UserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "El usuario no tiene ID"])
        }
        
        try await db.collection(usersCollection).document(userId).setData(from: user, merge: true)
    }
    
    func getUser(userId: String) async throws -> User? {
        let document = try await db.collection(usersCollection).document(userId).getDocument()
        
        guard document.exists else {
            return nil
        }
        
        var user = try document.data(as: User.self)
        user.id = document.documentID
        return user
    }
    
    func getUsers(userIds: [String]) async throws -> [User] {
        guard !userIds.isEmpty else {
            return []
        }
        
        var users: [User] = []
        let batchSize = 10
        for i in stride(from: 0, to: userIds.count, by: batchSize) {
            let endIndex = min(i + batchSize, userIds.count)
            let batch = Array(userIds[i..<endIndex])
            
            let querySnapshot = try await db.collection(usersCollection)
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments()
            
            for document in querySnapshot.documents {
                do {
                    var user = try document.data(as: User.self)
                    user.id = document.documentID
                    users.append(user)
                } catch {
                    continue
                }
            }
        }
        
        return users
    }
    
    func deleteUser(userId: String) async throws {
        try await db.collection(usersCollection).document(userId).delete()
    }
}
