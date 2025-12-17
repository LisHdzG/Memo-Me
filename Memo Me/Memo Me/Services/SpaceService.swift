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
    private var spaceListener: ListenerRegistration?
    private var publicSpacesListener: ListenerRegistration?
    private var userSpacesListener: ListenerRegistration?
    
    func getActiveSpaces(userId: String) async throws -> [Space] {
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("isPublic", isEqualTo: true)
            .getDocuments()
        
        var spaces: [Space] = []
        
        for document in querySnapshot.documents {
            let data = document.data()
            
            var members: [String] = []
            if let membersData = data["members"] as? [Any] {
                for member in membersData {
                    if let reference = member as? DocumentReference {
                        members.append(reference.documentID)
                    } else if let path = member as? String {
                        if path.contains("/") {
                            let components = path.split(separator: "/")
                            if let lastComponent = components.last {
                                members.append(String(lastComponent))
                            }
                        } else {
                            members.append(path)
                        }
                    }
                }
            }
            
            let isMember = members.contains { memberId in
                memberId == userId || 
                memberId == "users/\(userId)" ||
                memberId == "/users/\(userId)"
            }
            
            guard !isMember else { continue }
            
            let isPublic = data["isPublic"] as? Bool ?? false
            let isOfficial = data["isOfficial"] as? Bool ?? false
            let code = data["code"] as? String
            let description = data["description"] as? String ?? ""
            let types = data["types"] as? [String] ?? []
            
            var owner = ""
            if let ownerRef = data["owner"] as? DocumentReference {
                owner = "users/\(ownerRef.documentID)"
            } else if let ownerString = data["owner"] as? String {
                owner = ownerString
            }
            
            let space = Space(
                id: document.documentID,
                spaceId: data["spaceId"] as? String ?? "",
                name: data["name"] as? String ?? "",
                description: description,
                bannerUrl: data["bannerUrl"] as? String ?? "",
                members: members,
                isPublic: isPublic,
                isOfficial: isOfficial,
                code: code,
                owner: owner,
                types: types
            )
            
            spaces.append(space)
        }
        
        return spaces
    }
    
    func isUserMember(space: Space, userId: String) -> Bool {
        return space.members.contains { memberId in
            memberId == userId || 
            memberId == "users/\(userId)" ||
            memberId == "/users/\(userId)"
        }
    }
    
    func joinSpace(spaceId: String, userId: String) async throws {
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("spaceId", isEqualTo: spaceId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            throw NSError(domain: "SpaceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se encontró el espacio"])
        }
        
        let spaceRef = db.collection(spacesCollection).document(document.documentID)
        
        let spaceDocument = try await spaceRef.getDocument()
        guard spaceDocument.exists else {
            throw NSError(domain: "SpaceService", code: 2, userInfo: [NSLocalizedDescriptionKey: "El espacio no existe"])
        }
        
        let data = spaceDocument.data() ?? [:]
        var members: [Any] = data["members"] as? [Any] ?? []
        
        let userReference = db.collection("users").document(userId)
        let isAlreadyMember = members.contains { member in
            if let ref = member as? DocumentReference {
                return ref.documentID == userId
            } else if let path = member as? String {
                return path.contains(userId)
            }
            return false
        }
        
        guard !isAlreadyMember else {
            return
        }
        
        members.append(userReference)
        
        try await spaceRef.updateData([
            "members": members
        ])
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
    
    func getSpaceBySpaceId(_ spaceId: String) async throws -> Space? {
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("spaceId", isEqualTo: spaceId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            return nil
        }
        
        let data = document.data()
        
        var members: [String] = []
        if let membersData = data["members"] as? [Any] {
            for member in membersData {
                if let reference = member as? DocumentReference {
                    members.append(reference.documentID)
                } else if let path = member as? String {
                    if path.contains("/") {
                        let components = path.split(separator: "/")
                        if let lastComponent = components.last {
                            members.append(String(lastComponent))
                        }
                    } else {
                        members.append(path)
                    }
                }
            }
        }
        
        let isPublic = data["isPublic"] as? Bool ?? false
        let isOfficial = data["isOfficial"] as? Bool ?? false
        let code = data["code"] as? String
        let description = data["description"] as? String ?? ""
        let types = data["types"] as? [String] ?? []
        
        var owner = ""
        if let ownerRef = data["owner"] as? DocumentReference {
            owner = "users/\(ownerRef.documentID)"
        } else if let ownerString = data["owner"] as? String {
            owner = ownerString
        }
        
        let space = Space(
            id: document.documentID,
            spaceId: data["spaceId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            description: description,
            bannerUrl: data["bannerUrl"] as? String ?? "",
            members: members,
            isPublic: isPublic,
            isOfficial: isOfficial,
            code: code,
            owner: owner,
            types: types
        )
        
        return space
    }
    
    func createSpace(_ space: Space) async throws -> String {
        var membersReferences: [Any] = []
        for member in space.members {
            if member.hasPrefix("users/") {
                let userId = String(member.dropFirst(6))
                let userRef = db.collection("users").document(userId)
                membersReferences.append(userRef)
            } else {
                let userRef = db.collection("users").document(member)
                membersReferences.append(userRef)
            }
        }
        
        var ownerReference: Any
        if space.owner.hasPrefix("users/") {
            let userId = String(space.owner.dropFirst(6))
            ownerReference = db.collection("users").document(userId)
        } else {
            ownerReference = db.collection("users").document(space.owner)
        }
        
        var data: [String: Any] = [
            "spaceId": space.spaceId,
            "name": space.name,
            "description": space.description,
            "bannerUrl": space.bannerUrl,
            "members": membersReferences,
            "isPublic": space.isPublic,
            "isOfficial": space.isOfficial,
            "owner": ownerReference,
            "types": space.types
        ]
        
        if let code = space.code {
            data["code"] = code
        }
        
        let docRef = try await db.collection(spacesCollection).addDocument(data: data)
        return docRef.documentID
    }
    
    func updateSpace(_ space: Space) async throws {
        guard let spaceId = space.id else {
            throw NSError(domain: "SpaceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "El espacio no tiene ID"])
        }
        
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(space)
        try await db.collection(spacesCollection).document(spaceId).setData(data, merge: true)
    }
    
    func getUserSpaces(userId: String) async throws -> [Space] {
        let querySnapshot = try await db.collection(spacesCollection)
            .getDocuments()
        
        var spaces: [Space] = []
        
        for document in querySnapshot.documents {
            let data = document.data()
            
            var members: [String] = []
            if let membersData = data["members"] as? [Any] {
                for member in membersData {
                    if let reference = member as? DocumentReference {
                        members.append(reference.documentID)
                    } else if let path = member as? String {
                        if path.contains("/") {
                            let components = path.split(separator: "/")
                            if let lastComponent = components.last {
                                members.append(String(lastComponent))
                            }
                        } else {
                            members.append(path)
                        }
                    }
                }
            }
            
            let isMember = members.contains { memberId in
                memberId == userId || 
                memberId == "users/\(userId)" ||
                memberId == "/users/\(userId)"
            }
            
            guard isMember else { continue }
            
            let isPublic = data["isPublic"] as? Bool ?? false
            let isOfficial = data["isOfficial"] as? Bool ?? false
            let code = data["code"] as? String
            let description = data["description"] as? String ?? ""
            let types = data["types"] as? [String] ?? []
            
            var owner = ""
            if let ownerRef = data["owner"] as? DocumentReference {
                owner = "users/\(ownerRef.documentID)"
            } else if let ownerString = data["owner"] as? String {
                owner = ownerString
            }
            
            let space = Space(
                id: document.documentID,
                spaceId: data["spaceId"] as? String ?? "",
                name: data["name"] as? String ?? "",
                description: description,
                bannerUrl: data["bannerUrl"] as? String ?? "",
                members: members,
                isPublic: isPublic,
                isOfficial: isOfficial,
                code: code,
                owner: owner,
                types: types
            )
            
            spaces.append(space)
        }
        
        return spaces
    }
    
    func findSpaceByCode(_ code: String) async throws -> Space? {
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("code", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            return nil
        }
        
        let data = document.data()
        
        var members: [String] = []
        if let membersData = data["members"] as? [Any] {
            for member in membersData {
                if let reference = member as? DocumentReference {
                    members.append(reference.documentID)
                } else if let path = member as? String {
                    if path.contains("/") {
                        let components = path.split(separator: "/")
                        if let lastComponent = components.last {
                            members.append(String(lastComponent))
                        }
                    } else {
                        members.append(path)
                    }
                }
            }
        }
        
        let isPublic = data["isPublic"] as? Bool ?? false
        let isOfficial = data["isOfficial"] as? Bool ?? false
        let spaceCode = data["code"] as? String
        let description = data["description"] as? String ?? ""
        let types = data["types"] as? [String] ?? []
        
        var owner = ""
        if let ownerRef = data["owner"] as? DocumentReference {
            owner = "users/\(ownerRef.documentID)"
        } else if let ownerString = data["owner"] as? String {
            owner = ownerString
        }
        
        let space = Space(
            id: document.documentID,
            spaceId: data["spaceId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            description: description,
            bannerUrl: data["bannerUrl"] as? String ?? "",
            members: members,
            isPublic: isPublic,
            isOfficial: isOfficial,
            code: spaceCode,
            owner: owner,
            types: types
        )
        
        return space
    }
    
    func joinSpaceByCode(code: String, userId: String) async throws -> Space {
        guard let space = try await findSpaceByCode(code) else {
            throw NSError(domain: "SpaceService", code: 3, userInfo: [NSLocalizedDescriptionKey: "El código no es válido o el espacio no existe"])
        }
        
        let isAlreadyMember = isUserMember(space: space, userId: userId)
        
        if isAlreadyMember {
            return space
        }
        
        try await joinSpace(spaceId: space.spaceId, userId: userId)
        
        if let updatedSpace = try await findSpaceByCode(code) {
            return updatedSpace
        }
        
        return space
    }
    
    func generateCode(from name: String) -> String {
        let uppercased = name.uppercased()
        let withoutSpaces = uppercased.replacingOccurrences(of: " ", with: "_")
        let cleaned = withoutSpaces.filter { $0.isLetter || $0.isNumber || $0 == "_" }
        return cleaned.isEmpty ? "SPACE_\(UUID().uuidString.prefix(8).uppercased())" : cleaned
    }
    
    func generateSpaceId() -> String {
        let randomNumber = Int.random(in: 1...9999)
        return "HUB-\(randomNumber)"
    }
    
    func spaceIdExists(_ spaceId: String) async throws -> Bool {
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("spaceId", isEqualTo: spaceId)
            .limit(to: 1)
            .getDocuments()
        
        return !querySnapshot.documents.isEmpty
    }
    
    func generateUniqueSpaceId() async throws -> String {
        var spaceId = generateSpaceId()
        var attempts = 0
        let maxAttempts = 100
        
        while try await spaceIdExists(spaceId) && attempts < maxAttempts {
            spaceId = generateSpaceId()
            attempts += 1
        }
        
        if attempts >= maxAttempts {
            return "HUB-\(UUID().uuidString.prefix(8).uppercased())"
        }
        
        return spaceId
    }
    
    func listenToSpace(spaceId: String, onUpdate: @escaping (Space?) -> Void) {
        let query = db.collection(spacesCollection)
            .whereField("spaceId", isEqualTo: spaceId)
            .limit(to: 1)
        
        spaceListener = query.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                onUpdate(nil)
                return
            }
            
            let document = documents[0]
            let data = document.data()
            
            var members: [String] = []
            if let membersData = data["members"] as? [Any] {
                for member in membersData {
                    if let reference = member as? DocumentReference {
                        members.append(reference.documentID)
                    } else if let path = member as? String {
                        if path.contains("/") {
                            let components = path.split(separator: "/")
                            if let lastComponent = components.last {
                                members.append(String(lastComponent))
                            }
                        } else {
                            members.append(path)
                        }
                    }
                }
            }
            
            let isPublic = data["isPublic"] as? Bool ?? false
            let isOfficial = data["isOfficial"] as? Bool ?? false
            let code = data["code"] as? String
            let description = data["description"] as? String ?? ""
            let types = data["types"] as? [String] ?? []
            
            var owner = ""
            if let ownerRef = data["owner"] as? DocumentReference {
                owner = "users/\(ownerRef.documentID)"
            } else if let ownerString = data["owner"] as? String {
                owner = ownerString
            }
            
            let space = Space(
                id: document.documentID,
                spaceId: data["spaceId"] as? String ?? "",
                name: data["name"] as? String ?? "",
                description: description,
                bannerUrl: data["bannerUrl"] as? String ?? "",
                members: members,
                isPublic: isPublic,
                isOfficial: isOfficial,
                code: code,
                owner: owner,
                types: types
            )
            
            onUpdate(space)
        }
    }
    
    func stopListeningToSpace() {
        spaceListener?.remove()
        spaceListener = nil
    }
    
    func listenToAllSpaces(userId: String, onPublicSpacesUpdate: @escaping ([Space]) -> Void, onUserSpacesUpdate: @escaping ([Space]) -> Void) {
        stopListeningToAllSpaces()
        
        let publicSpacesQuery = db.collection(spacesCollection)
            .whereField("isPublic", isEqualTo: true)
        
        publicSpacesListener = publicSpacesQuery.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                onPublicSpacesUpdate([])
                return
            }
            
            var spaces: [Space] = []
            
            for document in documents {
                let data = document.data()
                
                var members: [String] = []
                if let membersData = data["members"] as? [Any] {
                    for member in membersData {
                        if let reference = member as? DocumentReference {
                            members.append(reference.documentID)
                        } else if let path = member as? String {
                            if path.contains("/") {
                                let components = path.split(separator: "/")
                                if let lastComponent = components.last {
                                    members.append(String(lastComponent))
                                }
                            } else {
                                members.append(path)
                            }
                        }
                    }
                }
                
                let isMember = members.contains { memberId in
                    memberId == userId ||
                    memberId == "users/\(userId)" ||
                    memberId == "/users/\(userId)"
                }
                
                guard !isMember else { continue }
                
                let isPublic = data["isPublic"] as? Bool ?? false
                let isOfficial = data["isOfficial"] as? Bool ?? false
                let code = data["code"] as? String
                let description = data["description"] as? String ?? ""
                let types = data["types"] as? [String] ?? []
                
                var owner = ""
                if let ownerRef = data["owner"] as? DocumentReference {
                    owner = "users/\(ownerRef.documentID)"
                } else if let ownerString = data["owner"] as? String {
                    owner = ownerString
                }
                
                let space = Space(
                    id: document.documentID,
                    spaceId: data["spaceId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    description: description,
                    bannerUrl: data["bannerUrl"] as? String ?? "",
                    members: members,
                    isPublic: isPublic,
                    isOfficial: isOfficial,
                    code: code,
                    owner: owner,
                    types: types
                )
                
                spaces.append(space)
            }
            
            onPublicSpacesUpdate(spaces)
        }
        
        let allSpacesQuery = db.collection(spacesCollection)
        
        userSpacesListener = allSpacesQuery.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                onUserSpacesUpdate([])
                return
            }
            
            var userSpaces: [Space] = []
            
            for document in documents {
                let data = document.data()
                
                var members: [String] = []
                if let membersData = data["members"] as? [Any] {
                    for member in membersData {
                        if let reference = member as? DocumentReference {
                            members.append(reference.documentID)
                        } else if let path = member as? String {
                            if path.contains("/") {
                                let components = path.split(separator: "/")
                                if let lastComponent = components.last {
                                    members.append(String(lastComponent))
                                }
                            } else {
                                members.append(path)
                            }
                        }
                    }
                }
                
                let isMember = members.contains { memberId in
                    memberId == userId ||
                    memberId == "users/\(userId)" ||
                    memberId == "/users/\(userId)"
                }
                
                guard isMember else { continue }
                
                let isPublic = data["isPublic"] as? Bool ?? false
                let isOfficial = data["isOfficial"] as? Bool ?? false
                let code = data["code"] as? String
                let description = data["description"] as? String ?? ""
                let types = data["types"] as? [String] ?? []
                
                var owner = ""
                if let ownerRef = data["owner"] as? DocumentReference {
                    owner = "users/\(ownerRef.documentID)"
                } else if let ownerString = data["owner"] as? String {
                    owner = ownerString
                }
                
                let space = Space(
                    id: document.documentID,
                    spaceId: data["spaceId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    description: description,
                    bannerUrl: data["bannerUrl"] as? String ?? "",
                    members: members,
                    isPublic: isPublic,
                    isOfficial: isOfficial,
                    code: code,
                    owner: owner,
                    types: types
                )
                
                userSpaces.append(space)
            }
            
            onUserSpacesUpdate(userSpaces)
        }
    }
    
    func stopListeningToAllSpaces() {
        publicSpacesListener?.remove()
        publicSpacesListener = nil
        userSpacesListener?.remove()
        userSpacesListener = nil
    }
    
    func leaveSpace(spaceId: String, userId: String) async throws {
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("spaceId", isEqualTo: spaceId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            throw NSError(domain: "SpaceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Space not found"])
        }
        
        let spaceRef = db.collection(spacesCollection).document(document.documentID)
        let spaceDocument = try await spaceRef.getDocument()
        
        guard spaceDocument.exists else {
            throw NSError(domain: "SpaceService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Space does not exist"])
        }
        
        let data = spaceDocument.data() ?? [:]
        var members: [Any] = data["members"] as? [Any] ?? []
        
        members = members.filter { member in
            if let ref = member as? DocumentReference {
                return ref.documentID != userId
            } else if let path = member as? String {
                return !path.contains(userId)
            }
            return true
        }
        
        try await spaceRef.updateData([
            "members": members
        ])
    }
}

