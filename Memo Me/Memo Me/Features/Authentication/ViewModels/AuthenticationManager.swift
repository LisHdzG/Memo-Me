//
//  AuthenticationManager.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import Foundation
import Combine
import AuthenticationServices
import FirebaseFirestore

enum AuthenticationState: Equatable {
    case idle
    case loading
    case authenticated
    case unauthenticated
    case needsRegistration
    case error(String)
    
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.authenticated, .authenticated),
             (.unauthenticated, .unauthenticated),
             (.needsRegistration, .needsRegistration):
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
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let appleUserIDKey = "appleUserID"
    private let isAuthenticatedKey = "isAuthenticated"
    private let savedUserEmailKey = "savedUserEmail"
    private let savedUserNameKey = "savedUserName"
    private let cachedUserKey = "cachedUser"
    
    private let userService = UserService()
    
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
        
        // Obtener nombre si está disponible
        var appleName: String? = nil
        if let fullName = appleIDCredential.fullName {
            let name = PersonNameComponentsFormatter().string(from: fullName)
            self.userName = name
            appleName = name
            userDefaults.set(name, forKey: savedUserNameKey)
        } else {
            // Intentar recuperar nombre guardado
            self.userName = userDefaults.string(forKey: savedUserNameKey)
        }
        
        // Guardar el appleId temporalmente
        userDefaults.set(userID, forKey: appleUserIDKey)
        
        // Verificar si el usuario existe en Firestore
        Task {
            await checkUserInFirestore(appleId: userID, appleName: appleName)
        }
    }
    
    private func checkUserInFirestore(appleId: String, appleName: String?) async {
        do {
            if let existingUser = try await userService.checkUserExists(appleId: appleId) {
                // Usuario existe - autenticado
                self.currentUser = existingUser
                self.userName = existingUser.name
                self.userDefaults.set(true, forKey: isAuthenticatedKey)
                self.isAuthenticated = true
                self.authenticationState = .authenticated
                self.errorMessage = nil
                
                // Guardar usuario en caché local
                saveUserToCache(existingUser)
                
                print("✅ Usuario encontrado en Firestore - User ID: \(appleId)")
            } else {
                // Usuario no existe - necesita registro
                // Guardar el nombre de Apple si está disponible para usarlo en el registro
                if let name = appleName {
                    self.userName = name
                    userDefaults.set(name, forKey: savedUserNameKey)
                }
                self.authenticationState = .needsRegistration
                self.isAuthenticated = false
                print("📝 Usuario no encontrado - necesita registro - Apple ID: \(appleId)")
            }
        } catch {
            print("❌ Error al verificar usuario en Firestore: \(error.localizedDescription)")
            self.handleError(error)
        }
    }
    
    /// Marca al usuario como autenticado después de completar el registro
    func completeRegistration(user: User) {
        self.currentUser = user
        self.userName = user.name
        self.userDefaults.set(true, forKey: isAuthenticatedKey)
        self.isAuthenticated = true
        self.authenticationState = .authenticated
        self.errorMessage = nil
        
        // Guardar usuario en caché local
        saveUserToCache(user)
        
        print("✅ Registro completado - Usuario autenticado")
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
        
        // Primero intentar cargar el usuario desde caché local
        if let cachedUser = loadUserFromCache(), cachedUser.appleId == userID {
            // Usuario encontrado en caché - usar datos locales sin llamar a Firestore
            self.currentUser = cachedUser
            self.userIdentifier = userID
            self.userName = cachedUser.name
            self.userEmail = self.userDefaults.string(forKey: self.savedUserEmailKey)
            self.isAuthenticated = true
            self.authenticationState = .authenticated
            self.errorMessage = nil
            print("✅ Usuario cargado desde caché local - User ID: \(userID)")
            return
        }
        
        // Si no hay usuario en caché, verificar con Apple y Firestore
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
                    self.userIdentifier = userID
                    self.userEmail = self.userDefaults.string(forKey: self.savedUserEmailKey)
                    self.userName = self.userDefaults.string(forKey: self.savedUserNameKey)
                    
                    // Verificar si el usuario existe en Firestore (solo si no está en caché)
                    if let existingUser = try? await self.userService.checkUserExists(appleId: userID) {
                        self.currentUser = existingUser
                        self.userName = existingUser.name
                        self.isAuthenticated = true
                        self.authenticationState = .authenticated
                        self.userDefaults.set(true, forKey: self.isAuthenticatedKey)
                        self.errorMessage = nil
                        
                        // Guardar usuario en caché local
                        self.saveUserToCache(existingUser)
                        
                        print("✅ Usuario autorizado y encontrado en Firestore - User ID: \(userID)")
                    } else {
                        // Usuario autorizado por Apple pero no existe en Firestore
                        // Esto puede pasar si el usuario se registró pero no completó el registro
                        self.isAuthenticated = false
                        self.authenticationState = .needsRegistration
                        print("⚠️ Usuario autorizado por Apple pero no encontrado en Firestore - necesita registro")
                    }
                    
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
        currentUser = nil
        userDefaults.removeObject(forKey: appleUserIDKey)
        userDefaults.removeObject(forKey: isAuthenticatedKey)
        userDefaults.removeObject(forKey: savedUserEmailKey)
        userDefaults.removeObject(forKey: savedUserNameKey)
        userDefaults.removeObject(forKey: cachedUserKey)
    }
    
    // MARK: - Cache Management
    
    /// Guarda el usuario en caché local (UserDefaults)
    private func saveUserToCache(_ user: User) {
        do {
            let encoder = JSONEncoder()
            let userData = try encoder.encode(user)
            userDefaults.set(userData, forKey: cachedUserKey)
            print("💾 Usuario guardado en caché local")
        } catch {
            print("⚠️ Error al guardar usuario en caché: \(error.localizedDescription)")
        }
    }
    
    /// Carga el usuario desde caché local (UserDefaults)
    private func loadUserFromCache() -> User? {
        guard let userData = userDefaults.data(forKey: cachedUserKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(User.self, from: userData)
            print("📦 Usuario cargado desde caché local")
            return user
        } catch {
            print("⚠️ Error al cargar usuario desde caché: \(error.localizedDescription)")
            // Si hay error al decodificar, limpiar el caché corrupto
            userDefaults.removeObject(forKey: cachedUserKey)
            return nil
        }
    }
    
    /// Actualiza el usuario en caché (útil para actualizar datos temporales)
    func updateCachedUser(_ user: User) {
        saveUserToCache(user)
        self.currentUser = user
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
