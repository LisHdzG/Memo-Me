//
//  OnboardingService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import Foundation

class OnboardingService {
    static let shared = OnboardingService()

    private let hasReachedSignInKey = "hasReachedSignIn"

    private init() {}

    var hasReachedSignIn: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasReachedSignInKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasReachedSignInKey)
        }
    }

    func markSignInReached() {
        hasReachedSignIn = true
    }

    func reset() {
        hasReachedSignIn = false
    }
}
