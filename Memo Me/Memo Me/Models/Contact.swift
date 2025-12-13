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
    let imageName: String
    
    init(id: UUID = UUID(), name: String, imageName: String) {
        self.id = id
        self.name = name
        self.imageName = imageName
    }
}

// MARK: - Dummy Data
extension Contact {
    static func generateDummyContacts() -> [Contact] {
        let names = [
            "María García", "Juan Pérez", "Ana Martínez", "Carlos López", "Laura Rodríguez",
            "Miguel Sánchez", "Sofía Fernández", "Diego González", "Isabella Torres", "Andrés Ramírez",
            "Valentina Morales", "Sebastián Herrera", "Camila Jiménez", "Nicolás Díaz", "Emma Castro",
            "Lucas Ruiz", "Olivia Vega", "Mateo Mendoza", "Amelia Rojas", "Santiago Vargas",
            "Mía Flores", "Benjamín Cruz", "Lucía Ortega", "Emilio Navarro", "Elena Moreno",
            "Daniel Silva", "Paula Romero", "Alejandro Gutiérrez", "Martina Delgado", "Gabriel Peña",
            "Victoria Ramos", "Adrián Medina", "Renata Aguilar", "Javier Suárez", "Isabela Castillo",
            "Tomás Paredes", "Antonella Núñez"
        ]
        
        return (1...37).enumerated().map { index, _ in
            let imageNumber = String(format: "%02d", index + 1)
            return Contact(
                name: names[safe: index] ?? "Contacto \(index + 1)",
                imageName: "dummy_profile_\(imageNumber)"
            )
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

