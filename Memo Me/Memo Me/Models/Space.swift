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
    var description: String
    var bannerUrl: String
    var members: [String]
    var isPublic: Bool
    var isOfficial: Bool
    var code: String?
    var owner: String
    var types: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case spaceId
        case name
        case description
        case bannerUrl
        case members
        case isPublic
        case isOfficial
        case code
        case owner
        case types
    }
    
    init(id: String? = nil, spaceId: String, name: String, description: String = "", bannerUrl: String = "", members: [String] = [], isPublic: Bool = false, isOfficial: Bool = false, code: String? = nil, owner: String = "", types: [String] = []) {
        self.id = id
        self.spaceId = spaceId
        self.name = name
        self.description = description
        self.bannerUrl = bannerUrl
        self.members = members
        self.isPublic = isPublic
        self.isOfficial = isOfficial
        self.code = code
        self.owner = owner
        self.types = types
    }
}

