//
//  ContactCacheService.swift
//  Memo Me
//
//  Created by Cursor on 16/12/25.
//

import Foundation

struct CachedContact: Codable, Equatable {
    let id: UUID
    let name: String
    let imageName: String?
    let imageUrl: String?
    let userId: String?
    
    init(from contact: Contact) {
        self.id = contact.id
        self.name = contact.name
        self.imageName = contact.imageName
        self.imageUrl = contact.imageUrl
        self.userId = contact.userId
    }
    
    func toContact() -> Contact {
        Contact(
            id: id,
            name: name,
            imageName: imageName,
            imageUrl: imageUrl,
            userId: userId
        )
    }
}

struct SpaceContactsCache: Codable {
    let spaceId: String
    let updatedAt: Date
    let contacts: [CachedContact]
}

@MainActor
final class ContactCacheService {
    static let shared = ContactCacheService()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKeyPrefix = "cachedContacts_"
    
    private init() {}
    
    func loadContacts(for spaceId: String) -> [Contact]? {
        guard let data = userDefaults.data(forKey: cacheKey(for: spaceId)) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(SpaceContactsCache.self, from: data)
            return cache.contacts.map { $0.toContact() }
        } catch {
            userDefaults.removeObject(forKey: cacheKey(for: spaceId))
            return nil
        }
    }
    
    func saveContacts(_ contacts: [Contact], for spaceId: String) {
        let cache = SpaceContactsCache(
            spaceId: spaceId,
            updatedAt: Date(),
            contacts: contacts.map { CachedContact(from: $0) }
        )
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cache)
            userDefaults.set(data, forKey: cacheKey(for: spaceId))
        } catch {
        }
    }
    
    func clearCache(for spaceId: String) {
        userDefaults.removeObject(forKey: cacheKey(for: spaceId))
    }
    
    func clearAll() {
        let keys = userDefaults.dictionaryRepresentation().keys
        let cacheKeys = keys.filter { $0.hasPrefix(cacheKeyPrefix) }
        for key in cacheKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
    
    private func cacheKey(for spaceId: String) -> String {
        "\(cacheKeyPrefix)\(spaceId)"
    }
}

