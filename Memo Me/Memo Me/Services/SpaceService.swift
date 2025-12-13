//
//  SpaceService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class SpaceService: ObservableObject {
    private let db = Firestore.firestore()
    private let spacesCollection = "spaces"
    
    func getActiveSpaces(userId: String) async throws -> [Space] {
        let querySnapshot = try await db.collection(spacesCollection)
            .getDocuments()
        
        var spaces: [Space] = []
        
        for document in querySnapshot.documents {
            do {
                let data = document.data()
                
                var memberIds: [String] = []
                if let memberIdsData = data["memberIds"] as? [Any] {
                    for memberId in memberIdsData {
                        if let reference = memberId as? DocumentReference {
                            memberIds.append(reference.documentID)
                        } else if let path = memberId as? String {
                            if path.contains("/") {
                                let components = path.split(separator: "/")
                                if let lastComponent = components.last {
                                    memberIds.append(String(lastComponent))
                                }
                            } else {
                                memberIds.append(path)
                            }
                        }
                    }
                }
                
                let isMember = memberIds.contains { memberId in
                    memberId == userId || 
                    memberId == "users/\(userId)" ||
                    memberId == "/users/\(userId)"
                }
                
                guard isMember else { continue }
                
                let space = Space(
                    id: document.documentID,
                    spaceId: data["spaceId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    bannerUrl: data["bannerUrl"] as? String ?? "",
                    memberIds: memberIds
                )
                
                spaces.append(space)
            } catch {
                continue
            }
        }
        
        return spaces
    }
    
    func getAllActiveSpaces() async throws -> [Space] {
        let querySnapshot = try await db.collection(spacesCollection)
            .getDocuments()
        
        var spaces: [Space] = []
        
        for document in querySnapshot.documents {
            do {
                var space = try document.data(as: Space.self)
                space.id = document.documentID
                spaces.append(space)
            } catch {
                continue
            }
        }
        
        return spaces
    }
    
    func getSpace(spaceId: String) async throws -> Space? {
        let document = try await db.collection(spacesCollection).document(spaceId).getDocument()
        
        guard document.exists else {
            return nil
        }
        
        var space = try document.data(as: Space.self)
        space.id = document.documentID
        return space
    }
    
    func createSpace(_ space: Space) async throws -> String {
        let docRef = try await db.collection(spacesCollection).addDocument(from: space)
        return docRef.documentID
    }
    
    func updateSpace(_ space: Space) async throws {
        guard let spaceId = space.id else {
            throw NSError(domain: "SpaceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "El espacio no tiene ID"])
        }
        
        try await db.collection(spacesCollection).document(spaceId).setData(from: space, merge: true)
    }
}

