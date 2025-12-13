//
//  SpaceSelectionService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import Combine

@MainActor
class SpaceSelectionService: ObservableObject {
    static let shared = SpaceSelectionService()
    
    @Published var selectedSpace: Space?
    
    private let userDefaults = UserDefaults.standard
    private let selectedSpaceKey = "selectedSpace"
    
    private init() {
        loadSelectedSpace()
    }
    
    /// Guarda el espacio seleccionado
    func saveSelectedSpace(_ space: Space) {
        selectedSpace = space
        
        do {
            let encoder = JSONEncoder()
            let spaceData = try encoder.encode(space)
            userDefaults.set(spaceData, forKey: selectedSpaceKey)
            print("💾 Espacio guardado: \(space.name)")
        } catch {
            print("⚠️ Error al guardar espacio: \(error.localizedDescription)")
        }
    }
    
    /// Carga el espacio seleccionado desde UserDefaults
    private func loadSelectedSpace() {
        guard let spaceData = userDefaults.data(forKey: selectedSpaceKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let space = try decoder.decode(Space.self, from: spaceData)
            selectedSpace = space
            print("📦 Espacio cargado desde caché: \(space.name)")
        } catch {
            print("⚠️ Error al cargar espacio desde caché: \(error.localizedDescription)")
            userDefaults.removeObject(forKey: selectedSpaceKey)
        }
    }
    
    /// Limpia el espacio seleccionado
    func clearSelectedSpace() {
        selectedSpace = nil
        userDefaults.removeObject(forKey: selectedSpaceKey)
        print("🗑️ Espacio seleccionado eliminado")
    }
}

