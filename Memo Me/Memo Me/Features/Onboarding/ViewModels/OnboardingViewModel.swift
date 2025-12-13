//
//  OnboardingViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import Foundation
import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
    
    let totalPages: Int = 3
    
    var pages: [OnboardingPage] {
        [
            OnboardingPage(
                title: "Remember",
                subtitle: "people",
                description: "effortlessly"
            ),
            OnboardingPage(
                title: "Organiza",
                subtitle: "tus contactos",
                description: "de forma inteligente"
            ),
            OnboardingPage(
                title: "Nunca olvides",
                subtitle: "nada importante",
                description: "sobre las personas"
            )
        ]
    }
    
    func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage += 1
            }
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage -= 1
            }
        }
    }
    
    func skipToRegistration() {
        // Esta función será llamada cuando el usuario presione Skip
        // La navegación se manejará en la vista
    }
    
    var isLastPage: Bool {
        currentPage == totalPages - 1
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
}

