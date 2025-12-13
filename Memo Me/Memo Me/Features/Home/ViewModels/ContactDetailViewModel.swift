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
    private var usersMap: [String: User] = [:]
    var currentUserId: String?
    
    func loadContacts(for space: Space?) async {
        guard let space = space, !space.memberIds.isEmpty else {
            contacts = []
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let users = try await userService.getUsers(userIds: space.memberIds)
            
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
    
    func getUser(for contact: Contact) -> User? {
        guard let userId = contact.userId else { return nil }
        return usersMap[userId]
    }
}

