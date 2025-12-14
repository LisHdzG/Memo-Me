//
//  ContactNoteService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation

struct ContactNote: Codable {
    let contactUserId: String
    let note: String
    let createdAt: Date
    let updatedAt: Date
    
    init(contactUserId: String, note: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.contactUserId = contactUserId
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

class ContactNoteService {
    static let shared = ContactNoteService()
    
    private let notesKey = "contactNotes"
    private let favoritesKey = "favoriteContacts"
    
    private init() {}
    
    func saveNote(contactUserId: String, note: String) {
        var notes = getAllNotes()
        
        if let index = notes.firstIndex(where: { $0.contactUserId == contactUserId }) {
            notes[index] = ContactNote(
                contactUserId: contactUserId,
                note: note,
                createdAt: notes[index].createdAt,
                updatedAt: Date()
            )
        } else {
            notes.append(ContactNote(contactUserId: contactUserId, note: note))
        }
        
        saveNotes(notes)
        
        if !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addFavorite(contactUserId: contactUserId)
        }
    }
    
    func getNote(contactUserId: String) -> String? {
        let notes = getAllNotes()
        return notes.first(where: { $0.contactUserId == contactUserId })?.note
    }
    
    func getAllNotes() -> [ContactNote] {
        guard let data = UserDefaults.standard.data(forKey: notesKey),
              let notes = try? JSONDecoder().decode([ContactNote].self, from: data) else {
            return []
        }
        return notes
    }
    
    func deleteNote(contactUserId: String) {
        var notes = getAllNotes()
        notes.removeAll(where: { $0.contactUserId == contactUserId })
        saveNotes(notes)
        
        removeFavorite(contactUserId: contactUserId)
    }
    
    private func saveNotes(_ notes: [ContactNote]) {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: notesKey)
        }
    }
    
    func addFavorite(contactUserId: String) {
        var favorites = getFavoriteUserIds()
        if !favorites.contains(contactUserId) {
            favorites.append(contactUserId)
            saveFavoriteUserIds(favorites)
        }
    }
    
    func removeFavorite(contactUserId: String) {
        var favorites = getFavoriteUserIds()
        favorites.removeAll(where: { $0 == contactUserId })
        saveFavoriteUserIds(favorites)
    }
    
    func isFavorite(contactUserId: String) -> Bool {
        let favorites = getFavoriteUserIds()
        return favorites.contains(contactUserId)
    }
    
    func getFavoriteUserIds() -> [String] {
        return UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
    }
    
    private func saveFavoriteUserIds(_ userIds: [String]) {
        UserDefaults.standard.set(userIds, forKey: favoritesKey)
    }
    
    func getFavoriteContactsWithNotes() -> [(userId: String, note: String?)] {
        let favorites = getFavoriteUserIds()
        let notes = getAllNotes()
        let notesMap = Dictionary(uniqueKeysWithValues: notes.map { ($0.contactUserId, $0.note) })
        
        return favorites.map { userId in
            (userId: userId, note: notesMap[userId])
        }
    }
}
