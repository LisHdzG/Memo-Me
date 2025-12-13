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
    
    /// Obtiene todos los espacios activos donde el usuario es miembro
    func getActiveSpaces(userId: String) async throws -> [Space] {
        // Obtener todos los espacios y filtrar en el cliente
        // Esto es más flexible y maneja diferentes formatos de memberIds
        let querySnapshot = try await db.collection(spacesCollection)
            .getDocuments()
        
        var spaces: [Space] = []
        
        for document in querySnapshot.documents {
            do {
                // Obtener los datos del documento
                let data = document.data()
                
                // Convertir memberIds si son referencias de Firestore o strings
                var memberIds: [String] = []
                if let memberIdsData = data["memberIds"] as? [Any] {
                    for memberId in memberIdsData {
                        if let reference = memberId as? DocumentReference {
                            // Si es una referencia de Firestore, obtener solo el ID del documento
                            memberIds.append(reference.documentID)
                        } else if let path = memberId as? String {
                            // Si es un string, puede ser una ruta completa o un ID
                            if path.contains("/") {
                                // Extraer el ID de la ruta (ej: "/users/ECknKORE2pNWvphhFagl" -> "ECknKORE2pNWvphhFagl")
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
                
                // Filtrar espacios donde el usuario es miembro
                // Comparar tanto con el ID directo como con posibles variaciones
                let isMember = memberIds.contains { memberId in
                    memberId == userId || 
                    memberId == "users/\(userId)" ||
                    memberId == "/users/\(userId)"
                }
                
                guard isMember else { continue }
                
                // Crear el espacio con los memberIds procesados
                let space = Space(
                    id: document.documentID,
                    spaceId: data["spaceId"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    bannerUrl: data["bannerUrl"] as? String ?? "",
                    memberIds: memberIds
                )
                
                spaces.append(space)
            } catch {
                print("⚠️ Error al procesar espacio \(document.documentID): \(error.localizedDescription)")
                // Continuar con el siguiente documento en lugar de fallar completamente
                continue
            }
        }
        
        return spaces
    }
    
    /// Obtiene todos los espacios activos (sin filtrar por usuario)
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
                print("⚠️ Error al decodificar espacio \(document.documentID): \(error.localizedDescription)")
                continue
            }
        }
        
        return spaces
    }
    
    /// Obtiene un espacio por su ID
    func getSpace(spaceId: String) async throws -> Space? {
        let document = try await db.collection(spacesCollection).document(spaceId).getDocument()
        
        guard document.exists else {
            return nil
        }
        
        var space = try document.data(as: Space.self)
        space.id = document.documentID
        return space
    }
    
    /// Crea un nuevo espacio
    func createSpace(_ space: Space) async throws -> String {
        let docRef = try await db.collection(spacesCollection).addDocument(from: space)
        return docRef.documentID
    }
    
    /// Actualiza un espacio existente
    func updateSpace(_ space: Space) async throws {
        guard let spaceId = space.id else {
            throw NSError(domain: "SpaceService", code: 1, userInfo: [NSLocalizedDescriptionKey: "El espacio no tiene ID"])
        }
        
        try await db.collection(spacesCollection).document(spaceId).setData(from: space, merge: true)
    }
}

