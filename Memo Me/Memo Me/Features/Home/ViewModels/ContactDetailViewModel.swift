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
    private let cacheService = ContactCacheService.shared
    private let networkMonitor = NetworkMonitor.shared
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
        currentSpaceId = space.spaceId
        
        let cachedContacts = cacheService.loadContacts(for: space.spaceId)
        if let cachedContacts {
            contacts = cachedContacts
            isLoading = false
        } else {
            contacts = []
            isLoading = true
            await LoaderPresenter.shared.show()
        }
        
        guard networkMonitor.isConnectedSync() else {
            isLoading = false
            await LoaderPresenter.shared.hide()
            return
        }
        
        await processSpaceMembers(space.members, shouldCache: true)
        
        spaceService.listenToSpace(spaceId: space.spaceId) { [weak self] updatedSpace in
            Task { @MainActor in
                guard let self = self, let updatedSpace = updatedSpace else {
                    return
                }
                await self.processSpaceMembers(updatedSpace.members, shouldCache: true)
            }
        }
        
        await startUserListeners(memberIds: space.members)
        
        isLoading = false
        await LoaderPresenter.shared.hide()
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
        
        guard networkMonitor.isConnectedSync(), !otherMemberIds.isEmpty else { return }
        
        userService.listenToUsers(userIds: otherMemberIds) { [weak self] updatedUsers in
            Task { @MainActor in
                guard let self = self else { return }
                
                var didChange = false
                for user in updatedUsers {
                    if let userId = user.id {
                        self.usersMap[userId] = user
                    }
                }
                
                didChange = self.updateContactsWithNewUserData(updatedUsers: updatedUsers)
                
                if didChange {
                    self.cacheCurrentContacts()
                }
            }
        }
    }
    
    @discardableResult
    private func updateContactsWithNewUserData(updatedUsers: [User]) -> Bool {
        var didChange = false
        for (index, contact) in contacts.enumerated() {
            if let userId = contact.userId,
               let updatedUser = updatedUsers.first(where: { $0.id == userId }) {
                
                let imageIndex = abs(userId.hashValue) % 37 + 1
                let imageNumber = String(format: "%02d", imageIndex)
                
                let newContact = Contact(
                    id: contact.id,
                    name: updatedUser.name,
                    imageName: updatedUser.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                    imageUrl: updatedUser.photoUrl,
                    userId: userId
                )
                
                if contacts[index] != newContact {
                    contacts[index] = newContact
                    didChange = true
                }
                
                if contact.imageUrl != updatedUser.photoUrl {
                    if let oldUrl = contact.imageUrl {
                        ImageLoaderService.shared.removeImage(from: oldUrl)
                    }
                }
            }
        }
        return didChange
    }
    
    private func stopUserListeners() {
        userService.stopListeningToUsers(userIds: currentMemberIds)
        currentMemberIds.removeAll()
    }
    
    private func processSpaceMembers(_ members: [String], shouldCache: Bool = false) async {
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
        
        if contacts.isEmpty {
            isLoading = true
        }
        
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
            
            let newContacts = filteredUsers.map { user in
                let imageIndex = abs(user.id?.hashValue ?? 0) % 37 + 1
                let imageNumber = String(format: "%02d", imageIndex)
                
                return Contact(
                    id: UUID(uuidString: user.id ?? UUID().uuidString) ?? UUID(),
                    name: user.name,
                    imageName: user.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                    imageUrl: user.photoUrl,
                    userId: user.id
                )
            }.sorted { lhs, rhs in
                let lhsId = lhs.userId ?? lhs.id.uuidString
                let rhsId = rhs.userId ?? rhs.id.uuidString
                return lhsId < rhsId
            }
            
            applyNewContacts(newContacts, shouldCache: shouldCache)
            isLoading = false
        } catch {
            errorMessage = "Error al cargar contactos: \(error.localizedDescription)"
            if contacts.isEmpty {
                contacts = []
            }
            isLoading = false
        }
    }
    
    private func applyNewContacts(_ newContacts: [Contact], shouldCache: Bool) {
        guard newContacts != contacts else { return }
        contacts = newContacts
        if shouldCache, let spaceId = currentSpaceId {
            cacheService.saveContacts(newContacts, for: spaceId)
        }
    }
    
    private func cacheCurrentContacts() {
        guard let spaceId = currentSpaceId else { return }
        cacheService.saveContacts(contacts, for: spaceId)
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
