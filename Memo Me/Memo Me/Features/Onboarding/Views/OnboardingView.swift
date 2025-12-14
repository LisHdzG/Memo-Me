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
    @State private var navigateToLogin = false
    @State private var navigateToRegistration = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.amethystLight)
                    .opacity(0.7)
                    .ignoresSafeArea()

                AnimatedPeopleCirclesView(
                    currentPage: viewModel.currentPage,
                    baseOpacity: 0.25
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    skipButton

                    Spacer()

                    TabView(selection: $viewModel.currentPage) {
                        ForEach(0..<viewModel.pages.count, id: \.self) { index in
                            OnboardingPageView(
                                page: viewModel.pages[index],
                                pageIndex: index
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))

                    Spacer()

                    CustomPageIndicator(
                        totalPages: viewModel.totalPages,
                        currentPage: viewModel.currentPage
                    )
                    .padding(.bottom, 50)

                    if viewModel.isLastPage {
                        continueButton
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginView()
                    .environmentObject(authManager)
            }
            .navigationDestination(isPresented: $navigateToRegistration) {
                RegistrationView()
                    .environmentObject(authManager)
            }
        }
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button(action: {
                navigateToLogin = true
            }) {
                Text("Skip")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
            .padding(.top, 8)
            .padding(.trailing, 20)
        }
    }

    private var continueButton: some View {
        Button(action: {
            navigateToLogin = true
        }) {
            Text("Continuar")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.black)
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int

    var body: some View {
        switch pageIndex {
        case 0:
            OnboardingFirstPageView(page: page)
        case 1:
            OnboardingSecondPageView(page: page)
        case 2:
            OnboardingThirdPageView(page: page)
        default:
            EmptyView()
        }
    }
}
