//
//  ContactVibeService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation

struct ContactVibe: Codable {
    let contactUserId: String
    let vibes: [String]
    let createdAt: Date
    let updatedAt: Date
    
    init(contactUserId: String, vibes: [String], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.contactUserId = contactUserId
        self.vibes = vibes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

class ContactVibeService {
    static let shared = ContactVibeService()
    
    private let vibesKey = "contactVibes"
    private let favoritesKey = "favoriteContacts"
    
    private init() {}
    
    func saveVibes(contactUserId: String, vibes: [String]) {
        var allVibes = getAllVibes()
        
        let validVibes = Array(vibes.prefix(2))
        guard !validVibes.isEmpty else {
            deleteVibes(contactUserId: contactUserId)
            return
        }
        
        if let index = allVibes.firstIndex(where: { $0.contactUserId == contactUserId }) {
            allVibes[index] = ContactVibe(
                contactUserId: contactUserId,
                vibes: validVibes,
                createdAt: allVibes[index].createdAt,
                updatedAt: Date()
            )
        } else {
            allVibes.append(ContactVibe(contactUserId: contactUserId, vibes: validVibes))
        }
        
        saveVibes(allVibes)
        
        if !validVibes.isEmpty {
            ContactNoteService.shared.addFavorite(contactUserId: contactUserId)
        }
    }
    
    func getVibes(contactUserId: String) -> [String] {
        let allVibes = getAllVibes()
        return allVibes.first(where: { $0.contactUserId == contactUserId })?.vibes ?? []
    }
    
    func getAllVibes() -> [ContactVibe] {
        guard let data = UserDefaults.standard.data(forKey: vibesKey),
              let vibes = try? JSONDecoder().decode([ContactVibe].self, from: data) else {
            return []
        }
        return vibes
    }
    
    func deleteVibes(contactUserId: String) {
        var allVibes = getAllVibes()
        allVibes.removeAll(where: { $0.contactUserId == contactUserId })
        saveVibes(allVibes)
        
        let noteService = ContactNoteService.shared
        if noteService.getNote(contactUserId: contactUserId) == nil ||
           noteService.getNote(contactUserId: contactUserId)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            noteService.removeFavorite(contactUserId: contactUserId)
        }
    }
    
    private func saveVibes(_ vibes: [ContactVibe]) {
        if let data = try? JSONEncoder().encode(vibes) {
            UserDefaults.standard.set(data, forKey: vibesKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    static let availableVibes: [VibeOption] = [
        VibeOption(id: "energizing", emoji: "⚡️", name: "Energizing"),
        VibeOption(id: "insightful", emoji: "💡", name: "Insightful"),
        VibeOption(id: "business", emoji: "💼", name: "Business"),
        VibeOption(id: "casual", emoji: "☕️", name: "Casual"),
        VibeOption(id: "fun", emoji: "😂", name: "Fun"),
        VibeOption(id: "ally", emoji: "🤝", name: "Ally"),
        VibeOption(id: "promising", emoji: "🌱", name: "Promising"),
        VibeOption(id: "fan", emoji: "🎉", name: "Fan"),
        VibeOption(id: "formal", emoji: "🧊", name: "Formal"),
        VibeOption(id: "social", emoji: "🍷", name: "Social"),
        VibeOption(id: "rushed", emoji: "🏃", name: "Rushed"),
        VibeOption(id: "curious", emoji: "❓", name: "Curious")
    ]
}

struct VibeOption: Identifiable, Codable {
    let id: String
    let emoji: String
    let name: String
}
