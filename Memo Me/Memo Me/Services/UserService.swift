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
    private var userListeners: [String: ListenerRegistration] = [:]
    
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
        
        let cleanedUserIds = userIds.map { userId -> String in
            if userId.contains("/") {
                let components = userId.split(separator: "/")
                if let lastComponent = components.last {
                    return String(lastComponent)
                }
            }
            return userId
        }
        
        var users: [User] = []
        let batchSize = 10
        for i in stride(from: 0, to: cleanedUserIds.count, by: batchSize) {
            let endIndex = min(i + batchSize, cleanedUserIds.count)
            let batch = Array(cleanedUserIds[i..<endIndex])
            
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
    
    func listenToUser(userId: String, onUpdate: @escaping (User?) -> Void) {
        stopListeningToUser(userId: userId)
        
        let userRef = db.collection(usersCollection).document(userId)
        let listener = userRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot, document.exists else {
                onUpdate(nil)
                return
            }
            
            do {
                var user = try document.data(as: User.self)
                user.id = document.documentID
                onUpdate(user)
            } catch {
                onUpdate(nil)
            }
        }
        
        userListeners[userId] = listener
    }
    
    func listenToUsers(userIds: [String], onUpdate: @escaping ([User]) -> Void) {
        stopListeningToUsers(userIds: userIds)
        
        let cleanedUserIds = userIds.map { userId -> String in
            if userId.contains("/") {
                let components = userId.split(separator: "/")
                if let lastComponent = components.last {
                    return String(lastComponent)
                }
            }
            return userId
        }
        
        var users: [User] = []
        var completedListeners = 0
        let totalUsers = cleanedUserIds.count
        
        for userId in cleanedUserIds {
            let userRef = db.collection(usersCollection).document(userId)
            let listener = userRef.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot, document.exists else {
                    completedListeners += 1
                    if completedListeners == totalUsers {
                        onUpdate(users)
                    }
                    return
                }
                
                do {
                    var user = try document.data(as: User.self)
                    user.id = document.documentID
                    
                    if let index = users.firstIndex(where: { $0.id == user.id }) {
                        users[index] = user
                    } else {
                        users.append(user)
                    }
                    
                    completedListeners += 1
                    if completedListeners == totalUsers {
                        onUpdate(users)
                    } else {
                        onUpdate(users)
                    }
                } catch {
                    completedListeners += 1
                    if completedListeners == totalUsers {
                        onUpdate(users)
                    }
                }
            }
            
            userListeners[userId] = listener
        }
    }
    
    func stopListeningToUser(userId: String) {
        let cleanedUserId = userId.contains("/") ? String(userId.split(separator: "/").last ?? "") : userId
        
        userListeners[cleanedUserId]?.remove()
        userListeners.removeValue(forKey: cleanedUserId)
    }
    
    func stopListeningToUsers(userIds: [String]) {
        for userId in userIds {
            stopListeningToUser(userId: userId)
        }
    }
    
    func stopAllUserListeners() {
        for (_, listener) in userListeners {
            listener.remove()
        }
        userListeners.removeAll()
    }
}
