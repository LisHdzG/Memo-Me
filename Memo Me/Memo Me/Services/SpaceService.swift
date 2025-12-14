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
                let isOfficial = data["isOfficial"] as? Bool ?? false
                let code = data["code"] as? String
                let description = data["description"] as? String ?? ""
                let types = data["types"] as? [String] ?? []
                
                // Manejar owner como DocumentReference o String
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
        // Convertir miembros de strings a referencias de Firestore
        var membersReferences: [Any] = []
        for member in space.members {
            // Si ya es una referencia en formato "users/userId", crear DocumentReference
            if member.hasPrefix("users/") {
                let userId = String(member.dropFirst(6)) // Remover "users/"
                let userRef = db.collection("users").document(userId)
                membersReferences.append(userRef)
            } else {
                // Si es solo el ID, crear la referencia completa
                let userRef = db.collection("users").document(member)
                membersReferences.append(userRef)
            }
        }
        
        // Crear referencia del owner
        var ownerReference: Any
        if space.owner.hasPrefix("users/") {
            let userId = String(space.owner.dropFirst(6))
            ownerReference = db.collection("users").document(userId)
        } else {
            ownerReference = db.collection("users").document(space.owner)
        }
        
        // Crear el documento con los datos correctos
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
                let isOfficial = data["isOfficial"] as? Bool ?? false
                let code = data["code"] as? String
                let description = data["description"] as? String ?? ""
                let types = data["types"] as? [String] ?? []
                
                // Manejar owner como DocumentReference o String
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
        let isOfficial = data["isOfficial"] as? Bool ?? false
        let spaceCode = data["code"] as? String
        let description = data["description"] as? String ?? ""
        let types = data["types"] as? [String] ?? []
        
        // Manejar owner como DocumentReference o String
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
    
    // MARK: - Space Creation Helpers
    
    /// Genera un código único basado en el nombre del espacio
    func generateCode(from name: String) -> String {
        // Convertir el nombre a mayúsculas y reemplazar espacios con guiones bajos
        let uppercased = name.uppercased()
        let withoutSpaces = uppercased.replacingOccurrences(of: " ", with: "_")
        // Remover caracteres especiales, mantener solo letras, números y guiones bajos
        let cleaned = withoutSpaces.filter { $0.isLetter || $0.isNumber || $0 == "_" }
        return cleaned.isEmpty ? "SPACE_\(UUID().uuidString.prefix(8).uppercased())" : cleaned
    }
    
    /// Genera un spaceId único en formato HUB-XX
    func generateSpaceId() -> String {
        // Generar un número aleatorio entre 1 y 9999
        let randomNumber = Int.random(in: 1...9999)
        return "HUB-\(randomNumber)"
    }
    
    /// Verifica si un spaceId ya existe
    func spaceIdExists(_ spaceId: String) async throws -> Bool {
        let querySnapshot = try await db.collection(spacesCollection)
            .whereField("spaceId", isEqualTo: spaceId)
            .limit(to: 1)
            .getDocuments()
        
        return !querySnapshot.documents.isEmpty
    }
    
    /// Genera un spaceId único que no existe en la base de datos
    func generateUniqueSpaceId() async throws -> String {
        var spaceId = generateSpaceId()
        var attempts = 0
        let maxAttempts = 100
        
        while try await spaceIdExists(spaceId) && attempts < maxAttempts {
            spaceId = generateSpaceId()
            attempts += 1
        }
        
        if attempts >= maxAttempts {
            // Si no se puede generar uno único después de muchos intentos, usar UUID
            return "HUB-\(UUID().uuidString.prefix(8).uppercased())"
        }
        
        return spaceId
    }
    
    // MARK: - Real-time Listeners
    
    /// Escucha cambios en tiempo real de un espacio específico
    func listenToSpace(spaceId: String, onUpdate: @escaping (Space?) -> Void) {
        // Primero encontrar el documento por spaceId
        let query = db.collection(spacesCollection)
            .whereField("spaceId", isEqualTo: spaceId)
            .limit(to: 1)
        
        // Escuchar cambios en la query
        spaceListener = query.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                onUpdate(nil)
                return
            }
            
            let document = documents[0]
            let data = document.data()
            
            // Procesar miembros
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
            
            // Manejar owner
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
    
    /// Detiene el listener del espacio
    func stopListeningToSpace() {
        spaceListener?.remove()
        spaceListener = nil
    }
    
    /// Escucha cambios en tiempo real de todos los espacios (públicos y del usuario)
    func listenToAllSpaces(userId: String, onPublicSpacesUpdate: @escaping ([Space]) -> Void, onUserSpacesUpdate: @escaping ([Space]) -> Void) {
        // Detener listener anterior si existe
        stopListeningToAllSpaces()
        
        // Listener para espacios públicos
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
                
                // Procesar miembros
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
                
                guard !isMember else { continue }
                
                let isPublic = data["isPublic"] as? Bool ?? false
                let isOfficial = data["isOfficial"] as? Bool ?? false
                let code = data["code"] as? String
                let description = data["description"] as? String ?? ""
                let types = data["types"] as? [String] ?? []
                
                // Manejar owner
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
        
        // Listener para espacios del usuario (todos los espacios donde el usuario es miembro)
        let allSpacesQuery = db.collection(spacesCollection)
        
        userSpacesListener = allSpacesQuery.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                onUserSpacesUpdate([])
                return
            }
            
            var userSpaces: [Space] = []
            
            for document in documents {
                let data = document.data()
                
                // Procesar miembros
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
                
                // Manejar owner
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
    
    /// Detiene el listener de todos los espacios
    func stopListeningToAllSpaces() {
        publicSpacesListener?.remove()
        publicSpacesListener = nil
        userSpacesListener?.remove()
        userSpacesListener = nil
    }
}

