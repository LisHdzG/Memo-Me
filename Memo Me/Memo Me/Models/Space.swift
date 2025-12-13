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
    var memberIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case spaceId
        case name
        case bannerUrl
        case memberIds
    }
    
    init(id: String? = nil, spaceId: String, name: String, bannerUrl: String = "", memberIds: [String] = []) {
        self.id = id
        self.spaceId = spaceId
        self.name = name
        self.bannerUrl = bannerUrl
        self.memberIds = memberIds
    }
}

