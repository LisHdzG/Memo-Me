//
//  ContactDetailViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import Foundation
import Combine
import CryptoKit

@MainActor
class ContactDetailViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var canShowInitialLoader: Bool = false
    
    private let initialLoaderKey = "hasShownContactsLoader"
    private let userService = UserService()
    private let spaceService = SpaceService()
    private let cacheService = ContactCacheService.shared
    private let networkMonitor = NetworkMonitor.shared
    private var usersMap: [String: User] = [:]
    var currentUserId: String?
    private var currentSpaceId: String?
    private var currentMemberIds: [String] = []
    private var isInitialized: Bool = false
    private var areListenersActive: Bool = false
    
    private var hasShownInitialLoader: Bool {
        get { UserDefaults.standard.bool(forKey: initialLoaderKey) }
        set { UserDefaults.standard.set(newValue, forKey: initialLoaderKey) }
    }
    
    func hasDataLoaded(for space: Space?) -> Bool {
        guard let space = space else { return false }
        return isInitialized && currentSpaceId == space.spaceId && !contacts.isEmpty
    }
    
    func loadContacts(for space: Space?, forceReload: Bool = false) async {
        guard let space = space else {
            stopListening()
            contacts = []
            isLoading = false
            canShowInitialLoader = false
            isInitialized = false
            return
        }
        
        let previousSpaceId = currentSpaceId
        let isSameSpace = previousSpaceId == space.spaceId
        
        if isSameSpace && isInitialized && !forceReload && !contacts.isEmpty {
            if !areListenersActive {
                spaceService.listenToSpace(spaceId: space.spaceId) { [weak self] updatedSpace in
                    Task { @MainActor in
                        guard let self = self, let updatedSpace = updatedSpace else {
                            return
                        }
                        await self.processSpaceMembers(updatedSpace.members, shouldCache: true)
                    }
                }
                startUserListeners(memberIds: space.members)
                areListenersActive = true
            }
            return
        }
        
        let shouldShowInitialLoader = !hasShownInitialLoader && !isSameSpace
        currentSpaceId = space.spaceId
        
        if !isSameSpace {
            stopListening()
        }
        
        let cachedContacts = cacheService.loadContacts(for: space.spaceId)
        if let cachedContacts, !forceReload {
            contacts = cachedContacts
            isLoading = false
            canShowInitialLoader = false
            
            Task {
                let cleanedMemberIds = space.members.map { memberId -> String in
                    if memberId.contains("/") {
                        let components = memberId.split(separator: "/")
                        if let lastComponent = components.last {
                            return String(lastComponent)
                        }
                    }
                    return memberId
                }
                
                do {
                    let users = try await userService.getUsers(userIds: cleanedMemberIds)
                    for user in users {
                        if let userId = user.id {
                            usersMap[userId] = user
                        }
                    }
                } catch {
                    // Silenciar error, los datos están en cache
                }
            }
        } else {
            contacts = []
            isLoading = true
            canShowInitialLoader = shouldShowInitialLoader
            if shouldShowInitialLoader {
                LoaderPresenter.shared.show()
            }
        }
        
        guard networkMonitor.isConnectedSync() else {
            isLoading = false
            if shouldShowInitialLoader {
                hasShownInitialLoader = true
                canShowInitialLoader = false
                LoaderPresenter.shared.hide()
            }
            if !isSameSpace {
                isInitialized = true
            }
            return
        }
        
        if cachedContacts == nil || forceReload {
            await processSpaceMembers(space.members, shouldCache: true)
        }
        
        if !areListenersActive || !isSameSpace {
            spaceService.listenToSpace(spaceId: space.spaceId) { [weak self] updatedSpace in
                Task { @MainActor in
                    guard let self = self, let updatedSpace = updatedSpace else {
                        return
                    }
                    await self.processSpaceMembers(updatedSpace.members, shouldCache: true)
                }
            }
            
            startUserListeners(memberIds: space.members)
            areListenersActive = true
        }
        
        isLoading = false
        isInitialized = true
        if shouldShowInitialLoader {
            hasShownInitialLoader = true
            canShowInitialLoader = false
            LoaderPresenter.shared.hide()
        }
    }
    
    private func startUserListeners(memberIds: [String]) {
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
                
                let newContact = buildContact(
                    from: updatedUser,
                    forcedId: contact.id
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
            
            let newContacts = filteredUsers
                .map { buildContact(from: $0) }
                .sorted { lhs, rhs in
                let lhsId = lhs.userId ?? lhs.id.uuidString
                let rhsId = rhs.userId ?? rhs.id.uuidString
                return lhsId < rhsId
            }
            
            applyNewContacts(newContacts, shouldCache: shouldCache)
            isLoading = false
        } catch {
            errorMessage = "Error loading contacts: \(error.localizedDescription)"
            if contacts.isEmpty {
                contacts = []
            }
            isLoading = false
            canShowInitialLoader = false
            if !hasShownInitialLoader {
                hasShownInitialLoader = true
                LoaderPresenter.shared.hide()
            }
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
        areListenersActive = false
    }
    
    func reset() {
        stopListening()
        currentSpaceId = nil
        contacts = []
        usersMap.removeAll()
        currentMemberIds.removeAll()
        isInitialized = false
        isLoading = false
        canShowInitialLoader = false
    }
    
    func getUser(for contact: Contact) -> User? {
        guard let userId = contact.userId else { return nil }
        return usersMap[userId]
    }
    
    
    private func buildContact(from user: User, forcedId: UUID? = nil) -> Contact {
        let userIdentifier = user.id ?? user.name
        let resolvedId = forcedId ?? contactId(for: userIdentifier)
        
        let imageIndex = stableIndex(from: userIdentifier, modulo: 37) + 1
        let imageNumber = String(format: "%02d", imageIndex)
        
        return Contact(
            id: resolvedId,
            name: user.name,
            imageName: user.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
            imageUrl: user.photoUrl,
            userId: user.id
        )
    }
    
    private func contactId(for identifier: String) -> UUID {
        if let uuid = UUID(uuidString: identifier) {
            return uuid
        }
        
        let digest = SHA256.hash(data: Data(identifier.utf8))
        var uuidBytes: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        
        withUnsafeMutableBytes(of: &uuidBytes) { buffer in
            let bytes = Array(digest.prefix(16))
            buffer.copyBytes(from: bytes)
        }
        
        return UUID(uuid: uuidBytes)
    }
    
    private func stableIndex(from identifier: String, modulo: Int) -> Int {
        let digest = SHA256.hash(data: Data(identifier.utf8))
        let value = digest.prefix(4).reduce(UInt32(0)) { partial, byte in
            (partial << 8) | UInt32(byte)
        }
        return Int(value % UInt32(modulo))
    }
}
