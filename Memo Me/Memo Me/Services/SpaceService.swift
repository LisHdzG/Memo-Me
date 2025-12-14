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
        // Obtener todos los espacios públicos
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("isPublic", isEqualTo: true)
            .getDocuments()
        
        var spaces: [Space] = []
        
        for document in querySnapshot.documents {
            do {
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
                
                // Verificar si el usuario ya es miembro - si lo es, no incluirlo en espacios públicos
                let isMember = members.contains { memberId in
                    memberId == userId || 
                    memberId == "users/\(userId)" ||
                    memberId == "/users/\(userId)"
                }
                
                // Solo agregar espacios públicos donde el usuario NO es miembro
                guard !isMember else { continue }
                
                let isPublic = data["isPublic"] as? Bool ?? false
                let code = data["code"] as? String
                
                let space = Space(
                    id: document.documentID,
                    spaceId: data["spaceId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    bannerUrl: data["bannerUrl"] as? String ?? "",
                    members: members,
                    isPublic: isPublic,
                    code: code
                )
                
                spaces.append(space)
            } catch {
                continue
            }
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
        // Buscar el espacio por spaceId
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("spaceId", isEqualTo: spaceId)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            throw NSError(domain: "SpaceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se encontró el espacio"])
        }
        
        let spaceRef = db.collection(spacesCollection).document(document.documentID)
        
        // Obtener el documento actual
        let spaceDocument = try await spaceRef.getDocument()
        guard spaceDocument.exists else {
            throw NSError(domain: "SpaceService", code: 2, userInfo: [NSLocalizedDescriptionKey: "El espacio no existe"])
        }
        
        let data = spaceDocument.data() ?? [:]
        var members: [Any] = data["members"] as? [Any] ?? []
        
        // Verificar si el usuario ya es miembro
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
            return // Ya es miembro, no hacer nada
        }
        
        // Agregar el usuario al array de miembros
        members.append(userReference)
        
        // Actualizar el documento
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
    
    func getUserSpaces(userId: String) async throws -> [Space] {
        // Obtener todos los espacios donde el usuario es miembro
        let querySnapshot = try await db.collection(spacesCollection)
            .getDocuments()
        
        var spaces: [Space] = []
        
        for document in querySnapshot.documents {
            do {
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
                let code = data["code"] as? String
                
                let space = Space(
                    id: document.documentID,
                    spaceId: data["spaceId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    bannerUrl: data["bannerUrl"] as? String ?? "",
                    members: members,
                    isPublic: isPublic,
                    code: code
                )
                
                spaces.append(space)
            } catch {
                continue
            }
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
        let spaceCode = data["code"] as? String
        
        let space = Space(
            id: document.documentID,
            spaceId: data["spaceId"] as? String ?? "",
            name: data["name"] as? String ?? "",
            bannerUrl: data["bannerUrl"] as? String ?? "",
            members: members,
            isPublic: isPublic,
            code: spaceCode
        )
        
        return space
    }
    
    func joinSpaceByCode(code: String, userId: String) async throws -> Space {
        guard let space = try await findSpaceByCode(code) else {
            throw NSError(domain: "SpaceService", code: 3, userInfo: [NSLocalizedDescriptionKey: "El código no es válido o el espacio no existe"])
        }
        
        // Verificar si el usuario ya es miembro
        let isAlreadyMember = isUserMember(space: space, userId: userId)
        
        if isAlreadyMember {
            // Si ya es miembro, retornar el espacio sin error
            return space
        }
        
        // Unirse al espacio (funciona para públicos y privados)
        try await joinSpace(spaceId: space.spaceId, userId: userId)
        
        // Retornar el espacio actualizado
        if let updatedSpace = try await findSpaceByCode(code) {
            return updatedSpace
        }
        
        return space
    }
    
    // Mantener compatibilidad con código existente
    func joinPrivateSpace(code: String, userId: String) async throws {
        _ = try await joinSpaceByCode(code: code, userId: userId)
    }
}

