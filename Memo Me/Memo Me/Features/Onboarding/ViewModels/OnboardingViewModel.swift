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
    private let onboardingService = OnboardingService.shared

    let totalPages: Int = 4

    init() {
        if onboardingService.hasReachedSignIn {
            currentPage = 3
        }
    }

    var pages: [OnboardingPage] {
        [
            OnboardingPage(
                title: "Do you remember the person… but not the name?",
                subtitle: "Contacts save numbers.\nMemoME saves stories.",
                description: ""
            ),
            OnboardingPage(
                title: "Organize people by spaces",
                subtitle: "No more \"where do I know them from?\"",
                description: "Everything has its place."
            ),
            OnboardingPage(
                title: "Remember what matters",
                subtitle: "",
                description: "That's MemoME."
            ),
            OnboardingPage(
                title: "",
                subtitle: "",
                description: ""
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
