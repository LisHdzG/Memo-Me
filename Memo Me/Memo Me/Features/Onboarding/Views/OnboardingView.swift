//
//  OnboardingView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = OnboardingViewModel()
    private let onboardingService = OnboardingService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.ghostWhite)
                    .ignoresSafeArea()

                if viewModel.currentPage < 3 {
                    AnimatedPeopleCirclesView(
                        currentPage: viewModel.currentPage,
                        baseOpacity: 0.10
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .opacity(viewModel.currentPage < 3 ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.6), value: viewModel.currentPage)
                }

                VStack(spacing: 0) {
                    if viewModel.currentPage < 3 {
                        skipButton
                    }

                    Spacer()

                    TabView(selection: $viewModel.currentPage) {
                        ForEach(0..<viewModel.pages.count, id: \.self) { index in
                            OnboardingPageView(
                                page: viewModel.pages[index],
                                pageIndex: index
                            )
                            .environmentObject(authManager)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.currentPage)
                    .onChange(of: viewModel.currentPage) { _, newValue in
                        if newValue == 3 {
                            onboardingService.markSignInReached()
                        }
                    }

                    Spacer()

                    CustomPageIndicator(
                        totalPages: viewModel.totalPages,
                        currentPage: viewModel.currentPage
                    )
                }
            }
        }
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button {
                viewModel.currentPage = 3
            } label: {
                Text("onboarding.skip", comment: "Skip button on onboarding")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .padding(.top, 8)
            .padding(.trailing, 20)
            .buttonStyle(.glass)
            .foregroundStyle(.primaryDark)
        }
    }

}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        switch pageIndex {
        case 0:
            OnboardingFirstPageView(page: page)
        case 1:
            OnboardingSecondPageView(page: page)
        case 2:
            OnboardingThirdPageView(page: page)
        case 3:
            OnboardingFourthPageView(showBackground: false)
                .environmentObject(authManager)
        default:
            EmptyView()
        }
    }
}
