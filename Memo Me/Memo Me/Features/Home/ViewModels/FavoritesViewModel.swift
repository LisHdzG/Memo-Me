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
    
    // Mantener compatibilidad con filtros individuales para la vista actual
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
        
        // Loader solo en la primera carga
        if !hasLoadedOnce {
            await LoaderPresenter.shared.show()
        }
        
        // Solo limpiar en la primera carga; en refrescos mantenemos datos actuales
        if !hasLoadedOnce {
            favoriteContacts = []
            filteredContacts = []
        }
        
        let localFavorites = noteService.getFavoriteUserIds()
        
        guard !localFavorites.isEmpty else {
            favoriteContacts = []
            filteredContacts = []
            hasLoadedOnce = true
            isLoading = false
            await LoaderPresenter.shared.hide()
            return
        }
        
        // Cargar información de espacios desde Firebase primero
        var spaceMap: [String: String] = [:]
        if let favoritesData = try? await favoriteService.getFavorites(userId: userId) {
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
        
        // Cargar todos los usuarios en paralelo
        let loadedFavorites = await withTaskGroup(of: FavoriteContact?.self) { group -> [FavoriteContact] in
            for contactUserId in localFavorites {
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
                    
                    // Obtener el espacio donde se conoció (desde Firebase si está disponible, sino "Personal")
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
        
        // Solo actualizar cuando todos los datos estén listos
        let sortedFavorites = loadedFavorites.sorted { $0.contact.name < $1.contact.name }
        
        // Actualizar ambas listas al mismo tiempo para evitar inconsistencias
        favoriteContacts = sortedFavorites
        filteredContacts = sortedFavorites
        hasLoadedOnce = true
        isLoading = false
        await LoaderPresenter.shared.hide()
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
        
        // Filtro por texto de búsqueda
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let searchLower = searchText.lowercased()
            
            filtered = filtered.filter { favoriteContact in
                // Buscar por nombre
                if favoriteContact.contact.name.lowercased().contains(searchLower) {
                    return true
                }
                
                // Buscar por espacio
                if favoriteContact.spaceName.lowercased().contains(searchLower) {
                    return true
                }
                
                // Buscar por vibes
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
                
                // Buscar por notas
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
        
        // Filtro por vibes (múltiples)
        if !selectedVibeFilters.isEmpty {
            filtered = filtered.filter { favoriteContact in
                guard let userId = favoriteContact.contact.userId else { return false }
                let vibes = getVibes(for: userId)
                return selectedVibeFilters.contains { vibeFilter in
                    vibes.contains(vibeFilter)
                }
            }
        }
        
        // Filtro por espacios (múltiples)
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
