//
//  LoginView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = AuthenticationManager()
    
    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                ContentView()
                    .transition(.opacity)
            } else {
                ZStack {
                    // Fondo con gradiente morado degradado (mismo que SplashView)
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
                        
                        // Logo o título
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
                        
                        // Mensaje de error si existe
                        if let errorMessage = viewModel.errorMessage {
                            VStack(spacing: 12) {
                                Text(errorMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Button(action: {
                                    viewModel.clearError()
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
                        
                        // Botón Sign in with Apple
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
                        .disabled(viewModel.authenticationState == .loading)
                        .opacity(viewModel.authenticationState == .loading ? 0.6 : 1.0)
                        
                        // Indicador de carga
                        if viewModel.authenticationState == .loading {
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
            viewModel.handleAuthorization(authorization)
            
        case .failure(let error):
            // Solo mostrar error si no fue cancelado por el usuario
            if let asError = error as? ASAuthorizationError,
               asError.code != .canceled {
                viewModel.handleError(error)
            } else if let asError = error as? ASAuthorizationError,
                      asError.code == .canceled {
                // Usuario canceló - no mostrar error, solo resetear estado
                viewModel.clearError()
            } else {
                viewModel.handleError(error)
            }
        }
    }
}

#Preview {
    LoginView()
}
