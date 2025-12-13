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
            
            contacts = users.map { user in
                let imageIndex = abs(user.id?.hashValue ?? 0) % 37 + 1
                let imageNumber = String(format: "%02d", imageIndex)
                
                return Contact(
                    id: UUID(uuidString: user.id ?? UUID().uuidString) ?? UUID(),
                    name: user.name,
                    imageName: user.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                    imageUrl: user.photoUrl
                )
            }
            
            isLoading = false
        } catch {
            errorMessage = "Error al cargar contactos: \(error.localizedDescription)"
            contacts = []
            isLoading = false
        }
    }
}

