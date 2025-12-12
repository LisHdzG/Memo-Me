//
//  AuthenticationManager.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import Foundation
import Combine
import AuthenticationServices

enum AuthenticationState: Equatable {
    case idle
    case loading
    case authenticated
    case unauthenticated
    case error(String)
    
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.authenticated, .authenticated),
             (.unauthenticated, .unauthenticated):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

enum AuthenticationError: LocalizedError {
    case cancelled
    case failed
    case invalidResponse
    case notHandled
    case unknown
    case networkError
    case credentialRevoked
    case credentialNotFound
    case checkStatusError(String)
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "El inicio de sesión fue cancelado"
        case .failed:
            return "Error al iniciar sesión. Por favor, intenta de nuevo"
        case .invalidResponse:
            return "Respuesta inválida del servidor"
        case .notHandled:
            return "No se pudo procesar la solicitud"
        case .unknown:
            return "Error desconocido. Por favor, intenta de nuevo"
        case .networkError:
            return "Error de conexión. Verifica tu conexión a internet"
        case .credentialRevoked:
            return "Las credenciales han sido revocadas. Por favor, inicia sesión nuevamente"
        case .credentialNotFound:
            return "No se encontraron credenciales guardadas"
        case .checkStatusError(let message):
            return "Error al verificar el estado: \(message)"
        }
    }
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authenticationState: AuthenticationState = .idle
    @Published var errorMessage: String?
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var userName: String?
    
    private let userDefaults = UserDefaults.standard
    private let appleUserIDKey = "appleUserID"
    private let isAuthenticatedKey = "isAuthenticated"
    private let savedUserEmailKey = "savedUserEmail"
    private let savedUserNameKey = "savedUserName"
    
    init() {
        checkAuthenticationStatus()
    }
    
    func handleAuthorization(_ authorization: ASAuthorization) {
        authenticationState = .loading
        errorMessage = nil
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let error = AuthenticationError.invalidResponse
            handleError(error)
            return
        }
        
        // Procesar credenciales
        let userID = appleIDCredential.user
        self.userIdentifier = userID
        
        // Obtener email y nombre (solo disponibles en el primer inicio de sesión)
        if let email = appleIDCredential.email {
            self.userEmail = email
            userDefaults.set(email, forKey: savedUserEmailKey)
        } else {
            // Intentar recuperar email guardado
            self.userEmail = userDefaults.string(forKey: savedUserEmailKey)
        }
        
        if let fullName = appleIDCredential.fullName {
            let name = PersonNameComponentsFormatter().string(from: fullName)
            self.userName = name
            userDefaults.set(name, forKey: savedUserNameKey)
        } else {
            // Intentar recuperar nombre guardado
            self.userName = userDefaults.string(forKey: savedUserNameKey)
        }
        
        // Guardar el estado de autenticación
        userDefaults.set(userID, forKey: appleUserIDKey)
        userDefaults.set(true, forKey: isAuthenticatedKey)
        
        // Marcar como autenticado
        self.isAuthenticated = true
        self.authenticationState = .authenticated
        self.errorMessage = nil
        
        print("✅ Sign in exitoso - User ID: \(userID)")
    }
    
    func handleError(_ error: Error) {
        let authError: AuthenticationError
        
        if let asError = error as? ASAuthorizationError {
            authError = mapASAuthorizationError(asError)
        } else if let customError = error as? AuthenticationError {
            authError = customError
        } else {
            authError = .unknown
        }
        
        self.authenticationState = .error(authError.errorDescription ?? "Error desconocido")
        self.errorMessage = authError.errorDescription
        self.isAuthenticated = false
        
        print("❌ Error de autenticación: \(authError.errorDescription ?? "Desconocido")")
    }
    
    private func mapASAuthorizationError(_ error: ASAuthorizationError) -> AuthenticationError {
        switch error.code {
        case .canceled:
            return .cancelled
        case .failed:
            return .failed
        case .invalidResponse:
            return .invalidResponse
        case .notHandled:
            return .notHandled
        case .unknown:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
    
    func checkAuthenticationStatus() {
        guard let userID = userDefaults.string(forKey: appleUserIDKey) else {
            authenticationState = .unauthenticated
            isAuthenticated = false
            return
        }
        
        authenticationState = .loading
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] credentialState, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    let authError = AuthenticationError.checkStatusError(error.localizedDescription)
                    self.handleError(authError)
                    return
                }
                
                switch credentialState {
                case .authorized:
                    self.isAuthenticated = true
                    self.userIdentifier = userID
                    self.userEmail = self.userDefaults.string(forKey: self.savedUserEmailKey)
                    self.userName = self.userDefaults.string(forKey: self.savedUserNameKey)
                    self.authenticationState = .authenticated
                    self.errorMessage = nil
                    print("✅ Usuario autorizado - User ID: \(userID)")
                    
                case .revoked:
                    self.clearAuthenticationData()
                    self.authenticationState = .unauthenticated
                    self.handleError(AuthenticationError.credentialRevoked)
                    
                case .notFound:
                    self.clearAuthenticationData()
                    self.authenticationState = .unauthenticated
                    self.handleError(AuthenticationError.credentialNotFound)
                    
                case .transferred:
                    // Las credenciales fueron transferidas a otro dispositivo
                    self.clearAuthenticationData()
                    self.authenticationState = .unauthenticated
                    self.handleError(AuthenticationError.credentialNotFound)
                    
                @unknown default:
                    self.authenticationState = .idle
                    print("⚠️ Estado de credencial desconocido")
                }
            }
        }
    }
    
    private func clearAuthenticationData() {
        isAuthenticated = false
        userIdentifier = nil
        userEmail = nil
        userName = nil
        userDefaults.removeObject(forKey: appleUserIDKey)
        userDefaults.removeObject(forKey: isAuthenticatedKey)
        userDefaults.removeObject(forKey: savedUserEmailKey)
        userDefaults.removeObject(forKey: savedUserNameKey)
    }
    
    func signOut() {
        clearAuthenticationData()
        authenticationState = .unauthenticated
        errorMessage = nil
        print("👋 Usuario cerró sesión")
    }
    
    func clearError() {
        errorMessage = nil
        if !isAuthenticated {
            authenticationState = .idle
        }
    }
}
