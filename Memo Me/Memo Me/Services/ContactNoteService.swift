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
        let cleanId = clean(contactUserId)
        var notes = getAllNotes()
        
        if let index = notes.firstIndex(where: { $0.contactUserId == cleanId }) {
            notes[index] = ContactNote(
                contactUserId: cleanId,
                note: note,
                createdAt: notes[index].createdAt,
                updatedAt: Date()
            )
        } else {
            notes.append(ContactNote(contactUserId: cleanId, note: note))
        }
        
        saveNotes(notes)
        
        if !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addFavorite(contactUserId: cleanId)
        }
    }
    
    func getNote(contactUserId: String) -> String? {
        let cleanId = clean(contactUserId)
        let notes = getAllNotes()
        return notes.first(where: { $0.contactUserId == cleanId })?.note
    }
    
    func getAllNotes() -> [ContactNote] {
        guard let data = UserDefaults.standard.data(forKey: notesKey),
              let notes = try? JSONDecoder().decode([ContactNote].self, from: data) else {
            return []
        }
        return notes
    }
    
    func deleteNote(contactUserId: String) {
        let cleanId = clean(contactUserId)
        var notes = getAllNotes()
        notes.removeAll(where: { $0.contactUserId == cleanId })
        saveNotes(notes)
    }
    
    private func saveNotes(_ notes: [ContactNote]) {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: notesKey)
        }
    }
    
    func addFavorite(contactUserId: String) {
        let cleanId = clean(contactUserId)
        var favorites = getFavoriteUserIds()
        if !favorites.contains(cleanId) {
            favorites.append(cleanId)
            saveFavoriteUserIds(favorites)
        }
    }
    
    func removeFavorite(contactUserId: String) {
        let cleanId = clean(contactUserId)
        var favorites = getFavoriteUserIds()
        favorites.removeAll(where: { $0 == cleanId })
        saveFavoriteUserIds(favorites)
    }
    
    func isFavorite(contactUserId: String) -> Bool {
        let cleanId = clean(contactUserId)
        let favorites = getFavoriteUserIds()
        return favorites.contains(cleanId)
    }
    
    func getFavoriteUserIds() -> [String] {
        let stored = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        return Array(Set(stored.map { clean($0) }))
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
    
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: notesKey)
        UserDefaults.standard.removeObject(forKey: favoritesKey)
    }
    
    private func clean(_ userId: String) -> String {
        if userId.contains("/") {
            let components = userId.split(separator: "/")
            if let last = components.last {
                return String(last)
            }
        }
        return userId.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
