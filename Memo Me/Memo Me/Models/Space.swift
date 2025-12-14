//
//  Space.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import FirebaseFirestore

struct Space: Codable, Identifiable, Equatable {
    var id: String?
    let spaceId: String
    let name: String
    var bannerUrl: String
    var members: [String]
    var isPublic: Bool
    var code: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case spaceId
        case name
        case bannerUrl
        case members
        case isPublic
        case code
    }
    
    init(id: String? = nil, spaceId: String, name: String, bannerUrl: String = "", members: [String] = [], isPublic: Bool = false, code: String? = nil) {
        self.id = id
        self.spaceId = spaceId
        self.name = name
        self.bannerUrl = bannerUrl
        self.members = members
        self.isPublic = isPublic
        self.code = code
    }
}

