//
//  LoginView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else if authManager.authenticationState == .needsRegistration {
                RegistrationView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("PurpleGradientTop"),
                            Color("PurpleGradientMiddle"),
                            Color("PurpleGradientBottom")
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Image("MemoMe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 150, height: 150)
                            
                            Text("Memo Me")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(Color("SplashTextColor"))
                        }
                        
                        Spacer()
                        
                        if let errorMessage = authManager.errorMessage {
                            VStack(spacing: 12) {
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button(action: {
                                    authManager.clearError()
                                }) {
                                    Text("Entendido")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.bottom, 10)
                        }
                        
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleSignInResult(result)
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                        .disabled(authManager.authenticationState == .loading)
                        .opacity(authManager.authenticationState == .loading ? 0.6 : 1.0)
                        
                        if authManager.authenticationState == .loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                                .padding(.top, 10)
                        }
                        
                        Spacer()
                            .frame(height: 50)
                    }
                }
            }
        }
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            authManager.handleAuthorization(authorization)
            
        case .failure(let error):
            if let asError = error as? ASAuthorizationError,
               asError.code != .canceled {
                authManager.handleError(error)
            } else if let asError = error as? ASAuthorizationError,
                      asError.code == .canceled {
                authManager.clearError()
            } else {
                authManager.handleError(error)
            }
        }
    }
}
