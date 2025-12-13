//
//  Contact.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import Foundation
import SwiftUI

struct Contact: Identifiable {
    let id: UUID
    let name: String
    let imageName: String?
    let imageUrl: String?
    let userId: String?
    
    init(id: UUID = UUID(), name: String, imageName: String? = nil, imageUrl: String? = nil, userId: String? = nil) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.imageUrl = imageUrl
        self.userId = userId
    }
}
