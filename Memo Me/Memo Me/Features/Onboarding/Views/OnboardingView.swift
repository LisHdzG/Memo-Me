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
                // Fondo con color al 70% de alpha para toda la vista
                Color("OnboardingBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            navigateToLogin = true
                        }) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(purpleColor)
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
                    
                    Spacer()
                    
                    TabView(selection: $viewModel.currentPage) {
                        ForEach(0..<viewModel.pages.count, id: \.self) { index in
                            OnboardingPageView(page: viewModel.pages[index], pageIndex: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                    
                    Spacer()
                    
                    CustomPageIndicator(
                        totalPages: viewModel.totalPages,
                        currentPage: viewModel.currentPage,
                        activeColor: purpleColor,
                        inactiveColor: purpleColor.opacity(0.5)
                    )
                    .padding(.bottom, 50)
                    
                    // Botón para continuar al login/registro
                    if viewModel.isLastPage {
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
                                        .fill(purpleColor)
                                )
                                .padding(.horizontal, 40)
                                .padding(.bottom, 30)
                        }
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
    
    private var purpleColor: Color {
        Color("PurpleGradientTop")
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int
    
    var isFirstPage: Bool {
        pageIndex == 0
    }
    
    var body: some View {
        if isFirstPage {
            firstPageView
        } else {
            defaultPageView
        }
    }
    
    private var firstPageView: some View {
        VStack(spacing: 0) {
            // Título y subtítulo en la parte superior
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(purpleColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                
                Text(page.subtitle)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(purpleColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
                    .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
            .zIndex(1) // Asegurar que el texto esté por encima
            
            // Área rectangular con los círculos animados (sin interferir con el texto)
            AnimatedPeopleCirclesView()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipped()
        }
    }
    
    private var defaultPageView: some View {
        VStack(spacing: 0) {
            Text(page.title)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(purpleColor)
            
            Text(page.subtitle)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(purpleColor)
            
            if !page.description.isEmpty {
                Text(page.description)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(purpleColor)
            }
        }
    }
    
    private var purpleColor: Color {
        Color("PurpleGradientTop")
    }
}
