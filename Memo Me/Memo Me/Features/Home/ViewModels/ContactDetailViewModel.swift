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
        
        stopListening()
        
        let wasSameSpace = currentSpaceId == space.spaceId
        currentSpaceId = space.spaceId
        
        if wasSameSpace {
            await processSpaceMembers(space.members)
            await startUserListeners(memberIds: space.members)
            spaceService.listenToSpace(spaceId: space.spaceId) { [weak self] updatedSpace in
                Task { @MainActor in
                    guard let self = self, let updatedSpace = updatedSpace else {
                        return
                    }
                    await self.processSpaceMembers(updatedSpace.members)
                }
            }
            return
        }
        
        await processSpaceMembers(space.members)
        
        spaceService.listenToSpace(spaceId: space.spaceId) { [weak self] updatedSpace in
            Task { @MainActor in
                guard let self = self, let updatedSpace = updatedSpace else {
                    return
                }
                await self.processSpaceMembers(updatedSpace.members)
            }
        }
        
        await startUserListeners(memberIds: space.members)
    }
    
    private func startUserListeners(memberIds: [String]) async {
        stopUserListeners()
        
        let cleanedMemberIds = memberIds.map { memberId -> String in
            if memberId.contains("/") {
                let components = memberId.split(separator: "/")
                if let lastComponent = components.last {
                    return String(lastComponent)
                }
            }
            return memberId
        }
        
        let otherMemberIds = cleanedMemberIds.filter { $0 != currentUserId }
        currentMemberIds = otherMemberIds
        
        userService.listenToUsers(userIds: otherMemberIds) { [weak self] updatedUsers in
            Task { @MainActor in
                guard let self = self else { return }
                
                for user in updatedUsers {
                    if let userId = user.id {
                        self.usersMap[userId] = user
                    }
                }
                
                self.updateContactsWithNewUserData(updatedUsers: updatedUsers)
            }
        }
    }
    
    private func updateContactsWithNewUserData(updatedUsers: [User]) {
        for (index, contact) in contacts.enumerated() {
            if let userId = contact.userId,
               let updatedUser = updatedUsers.first(where: { $0.id == userId }) {
                
                let imageIndex = abs(userId.hashValue) % 37 + 1
                let imageNumber = String(format: "%02d", imageIndex)
                
                contacts[index] = Contact(
                    id: contact.id,
                    name: updatedUser.name,
                    imageName: updatedUser.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                    imageUrl: updatedUser.photoUrl,
                    userId: userId
                )
                
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
        let cleanedMemberIds = members.map { memberId -> String in
            if memberId.contains("/") {
                let components = memberId.split(separator: "/")
                if let lastComponent = components.last {
                    return String(lastComponent)
                }
            }
            return memberId
        }
        
        guard !cleanedMemberIds.isEmpty else {
            contacts = []
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let users = try await userService.getUsers(userIds: cleanedMemberIds)
            
            usersMap.removeAll()
            for user in users {
                if let userId = user.id {
                    usersMap[userId] = user
                }
            }
            
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

