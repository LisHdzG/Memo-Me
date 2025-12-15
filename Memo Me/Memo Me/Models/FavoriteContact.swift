//
//  FavoriteContact.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation

struct FavoriteContact: Identifiable {
    let id: String
    let contact: Contact
    let spaceId: String
    let spaceName: String
    
    init(id: String = UUID().uuidString, contact: Contact, spaceId: String, spaceName: String) {
        self.id = id
        self.contact = contact
        self.spaceId = spaceId
        self.spaceName = spaceName
    }
}
