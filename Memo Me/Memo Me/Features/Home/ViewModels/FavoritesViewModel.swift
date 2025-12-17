//
//  FavoritesViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import Combine

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favoriteContacts: [FavoriteContact] = []
    @Published var filteredContacts: [FavoriteContact] = []
    @Published var searchText: String = ""
    @Published var selectedVibeFilters: [String] = []
    @Published var selectedSpaceFilters: [String] = []
    @Published var isLoading: Bool = true
    @Published var hasLoadedOnce: Bool = false
    @Published var errorMessage: String?
    @Published var showContactDetail: Bool = false
    @Published var selectedContact: Contact?
    @Published var selectedUser: User?
    
    var selectedVibeFilter: String? {
        get { selectedVibeFilters.first }
        set {
            if let newValue = newValue {
                selectedVibeFilters = [newValue]
            } else {
                selectedVibeFilters = []
            }
        }
    }
    
    var selectedSpaceFilter: String? {
        get { selectedSpaceFilters.first }
        set {
            if let newValue = newValue {
                selectedSpaceFilters = [newValue]
            } else {
                selectedSpaceFilters = []
            }
        }
    }
    
    private let userService = UserService()
    private let noteService = ContactNoteService.shared
    private let vibeService = ContactVibeService.shared
    private let favoriteService = FavoriteService()
    private let spaceService = SpaceService()
    
    func loadFavoriteContacts(userId: String) async {
        isLoading = true
        errorMessage = nil
        
        if !hasLoadedOnce {
            LoaderPresenter.shared.show()
        }
        
        if !hasLoadedOnce {
            favoriteContacts = []
            filteredContacts = []
        }
        
        let localFavorites = noteService.getFavoriteUserIds().map { id in
            if id.contains("/") {
                return String(id.split(separator: "/").last ?? "")
            }
            return id
        }
        let uniqueFavorites = Array(Set(localFavorites)).sorted()
        
        guard !uniqueFavorites.isEmpty else {
            favoriteContacts = []
            filteredContacts = []
            hasLoadedOnce = true
            isLoading = false
            LoaderPresenter.shared.hide()
            return
        }
        
        var spaceMap: [String: String] = [:]
        if let favoritesData = try? await favoriteService.getFavorites(userId: userId), !uniqueFavorites.isEmpty {
            await withTaskGroup(of: (String, String?).self) { group in
                for favoriteData in favoritesData {
                    group.addTask {
                        guard let contactUserId = favoriteData["contactUserId"] as? String,
                              let spaceId = favoriteData["spaceId"] as? String else {
                            return ("", nil)
                        }
                        if let space = try? await self.spaceService.getSpaceBySpaceId(spaceId) {
                            return (contactUserId, space.name)
                        }
                        return (contactUserId, nil)
                    }
                }
                
                for await (contactUserId, spaceName) in group {
                    if !contactUserId.isEmpty, let spaceName = spaceName {
                        spaceMap[contactUserId] = spaceName
                    }
                }
            }
        }
        
        let loadedFavorites = await withTaskGroup(of: FavoriteContact?.self) { group -> [FavoriteContact] in
            for contactUserId in uniqueFavorites {
                group.addTask { @MainActor in
                    guard let user = try? await self.userService.getUser(userId: contactUserId) else {
                        return nil
                    }
                    
                    let imageIndex = abs(contactUserId.hashValue) % 37 + 1
                    let imageNumber = String(format: "%02d", imageIndex)
                    
                    let contact = Contact(
                        id: UUID(uuidString: contactUserId) ?? UUID(),
                        name: user.name,
                        imageName: user.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                        imageUrl: user.photoUrl,
                        userId: contactUserId
                    )
                    
                    let spaceName = spaceMap[contactUserId] ?? "Personal"
                    
                    return FavoriteContact(
                        id: "local_\(contactUserId)",
                        contact: contact,
                        spaceId: "local",
                        spaceName: spaceName
                    )
                }
            }
            
            var results: [FavoriteContact] = []
            for await favoriteContact in group {
                if let favoriteContact = favoriteContact {
                    results.append(favoriteContact)
                }
            }
            return results
        }
        
        let sortedFavorites = loadedFavorites.sorted { $0.contact.name < $1.contact.name }
        
        favoriteContacts = sortedFavorites
        filteredContacts = sortedFavorites
        hasLoadedOnce = true
        isLoading = false
        LoaderPresenter.shared.hide()
    }
    
    func getVibes(for contactUserId: String) -> [String] {
        return vibeService.getVibes(contactUserId: contactUserId)
    }
    
    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !selectedVibeFilters.isEmpty ||
        !selectedSpaceFilters.isEmpty
    }
    
    var hasFilterOptions: Bool {
        !availableVibes.isEmpty || !availableSpaces.isEmpty
    }
    
    var availableSpaces: [String] {
        Array(Set(favoriteContacts.map { $0.spaceName })).sorted()
    }
    
    var availableVibes: [VibeOption] {
        let allVibesInContacts = Set(favoriteContacts.compactMap { contact -> [String]? in
            guard let userId = contact.contact.userId else { return nil }
            return getVibes(for: userId)
        }.flatMap { $0 })
        
        return ContactVibeService.availableVibes.filter { vibe in
            allVibesInContacts.contains(vibe.id)
        }
    }
    
    func filterContacts(searchText: String) {
        self.searchText = searchText
        applyFilters()
    }
    
    func applyFilters() {
        var filtered = favoriteContacts
        
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let searchLower = searchText.lowercased()
            
            filtered = filtered.filter { favoriteContact in
                if favoriteContact.contact.name.lowercased().contains(searchLower) {
                    return true
                }
                
                if favoriteContact.spaceName.lowercased().contains(searchLower) {
                    return true
                }
                
                if let userId = favoriteContact.contact.userId {
                    let vibes = getVibes(for: userId)
                    for vibeId in vibes {
                        if let vibe = ContactVibeService.availableVibes.first(where: { $0.id == vibeId }) {
                            if vibe.name.lowercased().contains(searchLower) ||
                               vibe.emoji.contains(searchText) {
                                return true
                            }
                        }
                    }
                }
                
                if let userId = favoriteContact.contact.userId,
                   let note = noteService.getNote(contactUserId: userId),
                   !note.isEmpty {
                    if note.lowercased().contains(searchLower) {
                        return true
                    }
                }
                
                return false
            }
        }
        
        if !selectedVibeFilters.isEmpty {
            filtered = filtered.filter { favoriteContact in
                guard let userId = favoriteContact.contact.userId else { return false }
                let vibes = getVibes(for: userId)
                return selectedVibeFilters.contains { vibeFilter in
                    vibes.contains(vibeFilter)
                }
            }
        }
        
        if !selectedSpaceFilters.isEmpty {
            filtered = filtered.filter { favoriteContact in
                selectedSpaceFilters.contains(favoriteContact.spaceName)
            }
        }
        
        filteredContacts = filtered
    }
    
    func clearAllFilters() {
        searchText = ""
        selectedVibeFilters = []
        selectedSpaceFilters = []
        applyFilters()
    }
}
