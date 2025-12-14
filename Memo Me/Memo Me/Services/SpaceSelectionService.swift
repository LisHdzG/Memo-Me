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
    @Published var hasContinuedWithoutSpace: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let selectedSpaceKey = "selectedSpace"
    private let hasContinuedWithoutSpaceKey = "hasContinuedWithoutSpace"
    
    private init() {
        loadSelectedSpace()
        loadHasContinuedWithoutSpace()
    }
    
    func saveSelectedSpace(_ space: Space) {
        selectedSpace = space
        
        do {
            let encoder = JSONEncoder()
            let spaceData = try encoder.encode(space)
            userDefaults.set(spaceData, forKey: selectedSpaceKey)
        } catch {
        }
    }
    
    private func loadSelectedSpace() {
        guard let spaceData = userDefaults.data(forKey: selectedSpaceKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let space = try decoder.decode(Space.self, from: spaceData)
            selectedSpace = space
        } catch {
            userDefaults.removeObject(forKey: selectedSpaceKey)
        }
    }
    
    func clearSelectedSpace() {
        selectedSpace = nil
        userDefaults.removeObject(forKey: selectedSpaceKey)
    }
    
    func markAsContinuedWithoutSpace() {
        hasContinuedWithoutSpace = true
        userDefaults.set(true, forKey: hasContinuedWithoutSpaceKey)
    }
    
    private func loadHasContinuedWithoutSpace() {
        hasContinuedWithoutSpace = userDefaults.bool(forKey: hasContinuedWithoutSpaceKey)
    }
    
    func resetContinueWithoutSpace() {
        hasContinuedWithoutSpace = false
        userDefaults.removeObject(forKey: hasContinuedWithoutSpaceKey)
    }
}

