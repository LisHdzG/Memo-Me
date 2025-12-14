//
//  OnboardingFourthPageView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI
import AuthenticationServices

struct OnboardingFourthPageView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showContent = false
    @State private var showTermsAndConditions = false
    let showBackground: Bool

    init(showBackground: Bool = true) {
        self.showBackground = showBackground
    }

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
                    if showBackground {
                        Color(.amethystLight)
                            .opacity(0.7)
                            .ignoresSafeArea()
                    }

                    VStack(spacing: 10) {
                        Spacer()

                        VStack(spacing: -10) {
                            Text("onboarding.page4.ready", comment: "You're ready to text")
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.7))
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(
                                    .spring(response: 0.8, dampingFraction: 0.7)
                                    .delay(0.3),
                                    value: showContent
                                )
                            Text("onboarding.page4.connect", comment: "Connect text")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.primaryDark)
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 20)
                                .animation(
                                    .spring(response: 0.8, dampingFraction: 0.7)
                                    .delay(0.3),
                                    value: showContent
                                )
                        }

                        Spacer()

                        VStack(spacing: 12) {
                            Image("MemoMeSignIn")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                                .opacity(showContent ? 1.0 : 0.0)
                                .scaleEffect(showContent ? 1.0 : 0.8)
                                .offset(y: showContent ? 0 : 20)
                                .animation(
                                    .spring(response: 0.8, dampingFraction: 0.7)
                                    .delay(0.35),
                                    value: showContent
                                )

                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: { result in
                                    handleSignInResult(result)
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                            .disabled(authManager.authenticationState == .loading)
                            .opacity(authManager.authenticationState == .loading ? 0.6 : (showContent ? 1.0 : 0.0))
                            .offset(y: showContent ? 0 : 30)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.7)
                                .delay(0.4),
                                value: showContent
                            )

                            if authManager.authenticationState == .loading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                                    .padding(.top, 10)
                            }

                            Button {
                                showTermsAndConditions = true
                            } label: {
                                termsAndConditionsText
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.7)
                                .delay(0.5),
                                value: showContent
                            )
                        }

                        Spacer()
                            .frame(height: 50)
                    }
                }
                .onAppear {
                    withAnimation {
                        showContent = true
                    }
                }
                .sheet(isPresented: $showTermsAndConditions) {
                    if let url = URL(string: "https://gemini.google.com/share/c363907dd45a") {
                        TermsAndConditionsView(url: url)
                    }
                }
            }
        }
    }

    private var termsAndConditionsText: Text {
        let fullText = String(localized: "onboarding.page4.terms")
        let boldKeywords = [
            "Terms and Conditions",
            "términos y condiciones",
            "Termini e Condizioni"
        ]

        guard let keyword = boldKeywords.first(where: { keyword in
            fullText.localizedCaseInsensitiveContains(keyword)
        }) else {
            return Text(fullText)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.7))
        }

        let nsString = fullText as NSString
        let options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let range = nsString.range(of: keyword, options: options)

        guard range.location != NSNotFound else {
            return Text(fullText)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.7))
        }

        let before = nsString.substring(to: range.location)
        let keywordText = nsString.substring(with: range)
        let after = nsString.substring(from: range.location + range.length)

        var attributedString = AttributedString(before)
        attributedString.font = .system(size: 12, weight: .regular, design: .rounded)
        attributedString.foregroundColor = .primaryDark.opacity(0.7)

        var keywordAttributed = AttributedString(keywordText)
        keywordAttributed.font = .system(size: 12, weight: .bold, design: .rounded)
        keywordAttributed.foregroundColor = .primaryDark.opacity(0.7)

        var afterAttributed = AttributedString(after)
        afterAttributed.font = .system(size: 12, weight: .regular, design: .rounded)
        afterAttributed.foregroundColor = .primaryDark.opacity(0.7)

        attributedString.append(keywordAttributed)
        attributedString.append(afterAttributed)

        return Text(attributedString)
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
