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
                title: "¿Te acuerdas de la persona… pero no del contexto?",
                subtitle: "Los contactos guardan números.\nMemoME guarda historias.",
                description: ""
            ),
            OnboardingPage(
                title: "Organiza personas por espacios",
                subtitle: "No más \"¿de dónde lo conozco?\"",
                description: "Todo tiene un lugar."
            ),
            OnboardingPage(
                title: "Recuerda lo que importa",
                subtitle: "Contexto. Personas. Memoria.",
                description: "Eso es MemoME."
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
    
    var isLastPage: Bool {
        currentPage == totalPages - 1
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
}
