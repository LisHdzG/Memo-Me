//
//  ContactDetailViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import Foundation
import Combine

@MainActor
class ContactDetailViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    private let userService = UserService()
    private let spaceService = SpaceService()
    private var usersMap: [String: User] = [:]
    var currentUserId: String?
    private var currentSpaceId: String?
    private var currentMemberIds: [String] = []
    
    func loadContacts(for space: Space?) async {
        guard let space = space else {
            stopListening()
            contacts = []
            isLoading = false
            return
        }
        
        // Si es el mismo espacio, no hacer nada (ya está escuchando)
        if currentSpaceId == space.spaceId {
            return
        }
        
        // Detener el listener anterior si existe
        stopListening()
        
        // Guardar el spaceId actual
        currentSpaceId = space.spaceId
        
        // Cargar contactos inicialmente
        await processSpaceMembers(space.members)
        
        // Iniciar listener en tiempo real del espacio
        spaceService.listenToSpace(spaceId: space.spaceId) { [weak self] updatedSpace in
            Task { @MainActor in
                guard let self = self, let updatedSpace = updatedSpace else {
                    return
                }
                await self.processSpaceMembers(updatedSpace.members)
            }
        }
        
        // Iniciar listeners en tiempo real de los usuarios para detectar cambios en fotos
        await startUserListeners(memberIds: space.members)
    }
    
    private func startUserListeners(memberIds: [String]) async {
        // Limpiar listeners anteriores
        stopUserListeners()
        
        // Limpiar los IDs
        let cleanedMemberIds = memberIds.map { memberId -> String in
            if memberId.contains("/") {
                let components = memberId.split(separator: "/")
                if let lastComponent = components.last {
                    return String(lastComponent)
                }
            }
            return memberId
        }
        
        // Filtrar el usuario actual
        let otherMemberIds = cleanedMemberIds.filter { $0 != currentUserId }
        currentMemberIds = otherMemberIds
        
        // Iniciar listeners para cada usuario
        userService.listenToUsers(userIds: otherMemberIds) { [weak self] updatedUsers in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Actualizar el mapa de usuarios
                for user in updatedUsers {
                    if let userId = user.id {
                        self.usersMap[userId] = user
                    }
                }
                
                // Actualizar los contactos con las nuevas fotos
                self.updateContactsWithNewUserData(updatedUsers: updatedUsers)
            }
        }
    }
    
    private func updateContactsWithNewUserData(updatedUsers: [User]) {
        // Actualizar los contactos existentes con los nuevos datos de usuario
        for (index, contact) in contacts.enumerated() {
            if let userId = contact.userId,
               let updatedUser = updatedUsers.first(where: { $0.id == userId }) {
                
                // Actualizar el contacto con la nueva foto
                let imageIndex = abs(userId.hashValue) % 37 + 1
                let imageNumber = String(format: "%02d", imageIndex)
                
                contacts[index] = Contact(
                    id: contact.id,
                    name: updatedUser.name,
                    imageName: updatedUser.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                    imageUrl: updatedUser.photoUrl,
                    userId: userId
                )
                
                // Invalidar el caché de la imagen si cambió
                if contact.imageUrl != updatedUser.photoUrl {
                    if let oldUrl = contact.imageUrl {
                        ImageLoaderService.shared.removeImage(from: oldUrl)
                    }
                }
            }
        }
    }
    
    private func stopUserListeners() {
        userService.stopListeningToUsers(userIds: currentMemberIds)
        currentMemberIds.removeAll()
    }
    
    private func processSpaceMembers(_ members: [String]) async {
        // Limpiar los IDs de miembros: extraer solo el ID del documento si viene en formato "users/userId" o "/users/userId"
        let cleanedMemberIds = members.map { memberId -> String in
            if memberId.contains("/") {
                // Si contiene "/", extraer solo el ID del documento
                let components = memberId.split(separator: "/")
                if let lastComponent = components.last {
                    return String(lastComponent)
                }
            }
            return memberId
        }
        
        print("DEBUG ContactDetailViewModel: Space members originales: \(members)")
        print("DEBUG ContactDetailViewModel: Space members limpiados: \(cleanedMemberIds)")
        
        guard !cleanedMemberIds.isEmpty else {
            print("DEBUG ContactDetailViewModel: No hay miembros después de limpiar")
            contacts = []
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("DEBUG ContactDetailViewModel: Buscando usuarios con IDs: \(cleanedMemberIds)")
            let users = try await userService.getUsers(userIds: cleanedMemberIds)
            print("DEBUG ContactDetailViewModel: Usuarios encontrados: \(users.count)")
            
            // Guardar usuarios en un mapa para acceso rápido
            usersMap.removeAll()
            for user in users {
                if let userId = user.id {
                    usersMap[userId] = user
                }
            }
            
            // Filtrar el usuario actual de la lista
            let filteredUsers = users.filter { user in
                guard let userId = user.id, let currentUserId = currentUserId else {
                    return true
                }
                return userId != currentUserId
            }
            
            contacts = filteredUsers.map { user in
                let imageIndex = abs(user.id?.hashValue ?? 0) % 37 + 1
                let imageNumber = String(format: "%02d", imageIndex)
                
                return Contact(
                    id: UUID(uuidString: user.id ?? UUID().uuidString) ?? UUID(),
                    name: user.name,
                    imageName: user.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                    imageUrl: user.photoUrl,
                    userId: user.id
                )
            }
            
            isLoading = false
        } catch {
            errorMessage = "Error al cargar contactos: \(error.localizedDescription)"
            contacts = []
            isLoading = false
        }
    }
    
    func stopListening() {
        spaceService.stopListeningToSpace()
        stopUserListeners()
        currentSpaceId = nil
    }
    
    func getUser(for contact: Contact) -> User? {
        guard let userId = contact.userId else { return nil }
        return usersMap[userId]
    }
}

