//
//  User.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    var id: String?
    let appleId: String
    var name: String
    var country: String?
    var areas: [String]?
    var interests: [String]?
    var photoUrl: String?
    var instagramUrl: String?
    var linkedinUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appleId
        case name
        case country
        case areas
        case interests
        case photoUrl
        case instagramUrl
        case linkedinUrl
    }
}
