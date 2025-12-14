//
//  SplashView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct SplashView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var isActive = false
    @State private var showMemo = false
    @State private var showMeReflection = false
    @State private var memoOffset: CGFloat = -30
    @State private var meReflectionOffset: CGFloat = 30
    @State private var imageOpacity: Double = 0
    @State private var imageScale: CGFloat = 0.8
    private let onboardingService = OnboardingService.shared

    var body: some View {
        if isActive {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else if onboardingService.hasReachedSignIn {
                OnboardingFourthPageView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            }
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        .focusRing,
                        .primaryAccent,
                        .primaryDark
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: -15) {
                        Text("Me")
                            .font(.system(size: 110, weight: .bold, design: .rounded))
                            .foregroundColor(.splashText)
                            .opacity(showMemo ? 1 : 0)
                            .offset(y: showMemo ? 0 : memoOffset)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("mo")
                            .font(.system(size: 110, weight: .bold, design: .rounded))
                            .foregroundColor(.splashText)
                            .opacity(showMemo ? 1 : 0)
                            .offset(y: showMemo ? 0 : memoOffset)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(alignment: .top, spacing: 16) {
                            Text("Me")
                                .font(.system(size: 110, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .splashText.opacity(0.4),
                                            .splashText.opacity(0.1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .opacity(showMeReflection ? 1 : 0)
                                .offset(y: showMeReflection ? 0 : meReflectionOffset)
                            
                            Image("MemoMe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                                .opacity(imageOpacity)
                                .scaleEffect(imageScale)
                                .padding(.top, -100)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    
                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showMemo = true
                    memoOffset = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showMeReflection = true
                        meReflectionOffset = 0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        imageOpacity = 1.0
                        imageScale = 1.0
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
