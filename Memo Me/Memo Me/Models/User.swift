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
    var nationality: String?
    var areas: [String]?
    var interests: [String]?
    var photoUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appleId
        case name
        case nationality
        case areas
        case interests
        case photoUrl
    }
}
