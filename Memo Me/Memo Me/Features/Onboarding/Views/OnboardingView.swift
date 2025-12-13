//
//  OnboardingView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var navigateToRegistration = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo blanco
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Botón Skip en la esquina superior derecha
                    HStack {
                        Spacer()
                        Button(action: {
                            navigateToRegistration = true
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
                    
                    // Contenido de la página actual
                    TabView(selection: $viewModel.currentPage) {
                        ForEach(0..<viewModel.pages.count, id: \.self) { index in
                            OnboardingPageView(page: viewModel.pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                    
                    Spacer()
                    
                    // Indicador de páginas custom
                    CustomPageIndicator(
                        totalPages: viewModel.totalPages,
                        currentPage: viewModel.currentPage,
                        activeColor: purpleColor,
                        inactiveColor: purpleColor.opacity(0.5)
                    )
                    .padding(.bottom, 50)
                }
            }
            .navigationDestination(isPresented: $navigateToRegistration) {
                RegistrationView()
            }
        }
    }
    
    private var purpleColor: Color {
        Color("PurpleGradientTop")
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 0) {
            Text(page.title)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(purpleColor)
            
            Text(page.subtitle)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(purpleColor)
            
            Text(page.description)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundColor(purpleColor)
        }
    }
    
    private var purpleColor: Color {
        Color("PurpleGradientTop")
    }
}
