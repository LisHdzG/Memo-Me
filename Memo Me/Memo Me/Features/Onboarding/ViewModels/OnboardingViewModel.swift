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
                title: String(localized: "onboarding.page1.title"),
                subtitle: String(localized: "onboarding.page1.subtitle"),
                description: ""
            ),
            OnboardingPage(
                title: String(localized: "onboarding.page2.title"),
                subtitle: String(localized: "onboarding.page2.subtitle"),
                description: String(localized: "onboarding.page2.description")
            ),
            OnboardingPage(
                title: String(localized: "onboarding.page3.title"),
                subtitle: "",
                description: String(localized: "onboarding.page3.description")
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
