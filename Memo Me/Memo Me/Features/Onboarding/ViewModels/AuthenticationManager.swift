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
    private let networkMonitor = NetworkMonitor.shared
    private let spaceSelectionService = SpaceSelectionService.shared
    private let contactCacheService = ContactCacheService.shared
    private var isSignInFlow = false
    
    init() {
        checkAuthenticationStatus()
    }
    
    func handleAuthorization(_ authorization: ASAuthorization) {
        guard networkMonitor.isConnectedSync() else {
            authenticationState = .idle
            errorMessage = nil
            let error = AuthenticationError.networkError
            handleError(error, retryAction: { [weak self] in
                ErrorPresenter.shared.dismiss()
                Task { @MainActor in
                    self?.isSignInFlow = false
                    self?.authenticationState = .idle
                    self?.errorMessage = nil
                }
            }, isSignInError: true)
            return
        }
        
        isSignInFlow = true
        authenticationState = .loading
        errorMessage = nil
        LoaderPresenter.shared.show()
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let error = AuthenticationError.invalidResponse
            handleError(error, retryAction: nil, isSignInError: true)
            return
        }
        
        let userID = appleIDCredential.user
        self.userIdentifier = userID
        
        if let email = appleIDCredential.email {
            self.userEmail = email
            userDefaults.set(email, forKey: savedUserEmailKey)
        } else {
            self.userEmail = userDefaults.string(forKey: savedUserEmailKey)
        }
        
        var appleName: String?
        if let fullName = appleIDCredential.fullName {
            let name = PersonNameComponentsFormatter().string(from: fullName)
            self.userName = name
            appleName = name
            userDefaults.set(name, forKey: savedUserNameKey)
        } else {
            self.userName = userDefaults.string(forKey: savedUserNameKey)
        }
        
        userDefaults.set(userID, forKey: appleUserIDKey)
        
        Task {
            await checkUserInFirestore(appleId: userID, appleName: appleName, isSignInFlow: true)
        }
    }
    
    private func checkUserInFirestore(appleId: String, appleName: String?, isSignInFlow: Bool = false) async {
        guard networkMonitor.isConnectedSync() else {
            LoaderPresenter.shared.hide()
            let error = AuthenticationError.networkError
            let retryAction: (() -> Void)? = isSignInFlow ? { [weak self] in
                ErrorPresenter.shared.dismiss()
                Task { @MainActor in
                    self?.isSignInFlow = false
                    self?.authenticationState = .idle
                    self?.errorMessage = nil
                }
            } : { [weak self] in
                Task { @MainActor in
                    LoaderPresenter.shared.show()
                    await self?.checkUserInFirestore(appleId: appleId, appleName: appleName, isSignInFlow: false)
                }
            }
            handleError(error, retryAction: retryAction, isSignInError: isSignInFlow)
            return
        }
        
        do {
            if let existingUser = try await userService.checkUserExists(appleId: appleId) {
                ErrorPresenter.shared.dismiss()
                LoaderPresenter.shared.hide()
                
                self.currentUser = existingUser
                self.userName = existingUser.name
                self.userDefaults.set(true, forKey: isAuthenticatedKey)
                self.isAuthenticated = true
                self.authenticationState = .authenticated
                self.errorMessage = nil
                
                saveUserToCache(existingUser)
            } else {
                ErrorPresenter.shared.dismiss()
                LoaderPresenter.shared.hide()
                
                if let name = appleName {
                    self.userName = name
                    userDefaults.set(name, forKey: savedUserNameKey)
                }
                self.authenticationState = .needsRegistration
                self.isAuthenticated = false
            }
        } catch {
            LoaderPresenter.shared.hide()
            let retryAction: (() -> Void)? = isSignInFlow ? { [weak self] in
                ErrorPresenter.shared.dismiss()
                Task { @MainActor in
                    self?.isSignInFlow = false
                    self?.authenticationState = .idle
                    self?.errorMessage = nil
                }
            } : { [weak self] in
                Task { @MainActor in
                    LoaderPresenter.shared.show()
                    await self?.checkUserInFirestore(appleId: appleId, appleName: appleName, isSignInFlow: false)
                }
            }
            
            self.handleError(error, retryAction: retryAction, isSignInError: isSignInFlow)
        }
    }
    
    func completeRegistration(user: User) {
        self.currentUser = user
        self.userName = user.name
        self.userDefaults.set(true, forKey: isAuthenticatedKey)
        self.isAuthenticated = true
        self.authenticationState = .authenticated
        self.errorMessage = nil
        
        saveUserToCache(user)
    }
    
    func handleError(_ error: Error, retryAction: (() -> Void)? = nil, isSignInError: Bool = false) {
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
        LoaderPresenter.shared.hide()
        
        let finalRetryAction = retryAction ?? (isSignInError ? { [weak self] in
            ErrorPresenter.shared.dismiss()
            Task { @MainActor in
                self?.isSignInFlow = false
                self?.authenticationState = .idle
                self?.errorMessage = nil
            }
        } : nil)
        
        if isNetworkError(error) {
            ErrorPresenter.shared.showNetworkError(retry: finalRetryAction)
        } else {
            ErrorPresenter.shared.showServiceError(retry: finalRetryAction)
        }
    }
    
    private func isNetworkError(_ error: Error) -> Bool {
        if !networkMonitor.isConnectedSync() {
            return true
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .cannotConnectToHost,
                 .timedOut,
                 .cannotFindHost,
                 .dnsLookupFailed,
                 .internationalRoamingOff,
                 .callIsActive,
                 .dataNotAllowed:
                return true
            default:
                return false
            }
        }
        
        if let nsError = error as NSError? {
            let firestoreErrorDomain = "FIRFirestoreErrorDomain"
            if nsError.domain == firestoreErrorDomain {
                if nsError.code == 14 || nsError.code == 4 || nsError.code == 8 || nsError.code == 13 {
                    return true
                }
            }
            
            if nsError.domain == "NSURLErrorDomain" {
                let networkErrorCodes = [-1009, -1005, -1004, -1001, -1003, -1006, -1018, -1019, -1020]
                if networkErrorCodes.contains(nsError.code) {
                    return true
                }
            }
            
            let errorMessage = nsError.localizedDescription.lowercased()
            let networkKeywords = ["network", "connection", "internet", "conexión", "red", "conectividad", "timeout", "unreachable", "unavailable", "offline", "sin conexión"]
            if networkKeywords.contains(where: errorMessage.contains) {
                return true
            }
            
            if let failureReason = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                let failureReasonLower = failureReason.lowercased()
                if networkKeywords.contains(where: failureReasonLower.contains) {
                    return true
                }
            }
        }
        
        return false
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
        default:
            return .unknown
        }
    }
    
    func checkAuthenticationStatus() {
        guard let userID = userDefaults.string(forKey: appleUserIDKey) else {
            authenticationState = .unauthenticated
            isAuthenticated = false
            return
        }
        
        if let cachedUser = loadUserFromCache(), cachedUser.appleId == userID {
            self.currentUser = cachedUser
            self.userIdentifier = userID
            self.userName = cachedUser.name
            self.userEmail = self.userDefaults.string(forKey: self.savedUserEmailKey)
            self.isAuthenticated = true
            self.authenticationState = .authenticated
            self.errorMessage = nil
            return
        }
        
        authenticationState = .loading
        LoaderPresenter.shared.show()
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] credentialState, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    LoaderPresenter.shared.hide()
                    self.handleError(error, retryAction: { [weak self] in
                        guard let self = self else { return }
                        LoaderPresenter.shared.show()
                        self.checkAuthenticationStatus()
                    })
                    return
                }
                
                switch credentialState {
                case .authorized:
                    self.userIdentifier = userID
                    self.userEmail = self.userDefaults.string(forKey: self.savedUserEmailKey)
                    self.userName = self.userDefaults.string(forKey: self.savedUserNameKey)
                    
                    do {
                        if let existingUser = try await self.userService.checkUserExists(appleId: userID) {
                            ErrorPresenter.shared.dismiss()
                            LoaderPresenter.shared.hide()
                            
                            self.currentUser = existingUser
                            self.userName = existingUser.name
                            self.isAuthenticated = true
                            self.authenticationState = .authenticated
                            self.userDefaults.set(true, forKey: self.isAuthenticatedKey)
                            self.errorMessage = nil
                            
                            self.saveUserToCache(existingUser)
                        } else {
                            ErrorPresenter.shared.dismiss()
                            LoaderPresenter.shared.hide()
                            
                            self.isAuthenticated = false
                            self.authenticationState = .needsRegistration
                        }
                    } catch {
                        LoaderPresenter.shared.hide()
                        self.handleError(error, retryAction: { [weak self] in
                            Task { @MainActor in
                                guard let self = self else { return }
                                LoaderPresenter.shared.show()
                                if let existingUser = try? await self.userService.checkUserExists(appleId: userID) {
                                    ErrorPresenter.shared.dismiss()
                                    LoaderPresenter.shared.hide()
                                    self.currentUser = existingUser
                                    self.userName = existingUser.name
                                    self.isAuthenticated = true
                                    self.authenticationState = .authenticated
                                    self.userDefaults.set(true, forKey: self.isAuthenticatedKey)
                                    self.errorMessage = nil
                                    self.saveUserToCache(existingUser)
                                } else {
                                    ErrorPresenter.shared.dismiss()
                                    LoaderPresenter.shared.hide()
                                    self.isAuthenticated = false
                                    self.authenticationState = .needsRegistration
                                }
                            }
                        }, isSignInError: false)
                    }
                    
                case .revoked:
                    self.clearAuthenticationData(clearLocalData: true)
                    self.authenticationState = .unauthenticated
                    self.handleError(AuthenticationError.credentialRevoked)
                    
                case .notFound:
                    self.clearAuthenticationData(clearLocalData: true)
                    self.authenticationState = .unauthenticated
                    self.handleError(AuthenticationError.credentialNotFound)
                    
                case .transferred:
                    self.clearAuthenticationData(clearLocalData: true)
                    self.authenticationState = .unauthenticated
                    self.handleError(AuthenticationError.credentialNotFound)
                    
                @unknown default:
                    self.authenticationState = .idle
                }
            }
        }
    }
    
    private func clearAuthenticationData(clearLocalData: Bool) {
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
        spaceSelectionService.clearSelectedSpace()
        spaceSelectionService.resetContinueWithoutSpace()
        if clearLocalData {
            contactCacheService.clearAll()
            ContactNoteService.shared.clearAll()
            ContactVibeService.shared.clearAll()
        }
    }
    
    private func saveUserToCache(_ user: User) {
        do {
            let encoder = JSONEncoder()
            let userData = try encoder.encode(user)
            userDefaults.set(userData, forKey: cachedUserKey)
        } catch {
        }
    }
    
    private func loadUserFromCache() -> User? {
        guard let userData = userDefaults.data(forKey: cachedUserKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(User.self, from: userData)
            return user
        } catch {
            userDefaults.removeObject(forKey: cachedUserKey)
            return nil
        }
    }
    
    func updateCachedUser(_ user: User) {
        saveUserToCache(user)
        self.currentUser = user
    }
    
    func signOut(clearLocalData: Bool = false) {
        clearAuthenticationData(clearLocalData: clearLocalData)
        authenticationState = .unauthenticated
        errorMessage = nil
    }
    
    func clearError() {
        errorMessage = nil
        if !isAuthenticated {
            authenticationState = .idle
        }
    }
}
