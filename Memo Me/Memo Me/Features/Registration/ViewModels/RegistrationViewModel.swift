//
//  RegistrationViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import PhotosUI
import Combine

@MainActor
class RegistrationViewModel: ObservableObject {
    @Published var profileImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var name: String = ""
    @Published var country: String?
    @Published var primaryExpertiseArea: String?
    @Published var secondaryExpertiseArea: String?
    
    @Published var countryConfig: PickerConfig = .init(text: "Select your country")
    @Published var primaryExpertiseConfig: PickerConfig = .init(text: "Select your professional interests")
    @Published var secondaryExpertiseConfig: PickerConfig = .init(text: "Select your professional interests")
    
    @Published var nameError: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userService = UserService()
    private let profileImageService = ProfileImageService.shared
    private let selectionListsService = SelectionListsService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    var authenticationManager: AuthenticationManager?
    
    var countries: [String] {
        selectionListsService.countries
    }
    
    var notInListCountry: String {
        selectionListsService.notInListCountry
    }
    
    var expertiseAreas: [String] {
        selectionListsService.expertiseAreas
    }
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init() {
        setupPhotoObserver()
    }
    
    private func setupPhotoObserver() {
        $selectedPhotoItem
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { @MainActor in
                    await self?.loadPhoto(from: item)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadPhoto(from item: PhotosPickerItem) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.profileImage = image
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "No se pudo cargar la imagen"
                        self.isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "Error al procesar la imagen"
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Error: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func removePhoto() {
        profileImage = nil
        selectedPhotoItem = nil
    }
    
    func validateName() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            nameError = "Name is required"
        } else if trimmedName.count < 2 {
            nameError = "Name must be at least 2 characters"
        } else if trimmedName.count > 50 {
            nameError = "Name cannot exceed 50 characters"
        } else {
            nameError = nil
        }
    }
    
    func selectCountry(_ country: String) {
        self.country = country
        countryConfig.text = country
    }
    
    func selectPrimaryExpertise(_ expertise: String) {
        if secondaryExpertiseArea == expertise {
            if let oldPrimary = primaryExpertiseArea {
                secondaryExpertiseArea = oldPrimary
                secondaryExpertiseConfig.text = oldPrimary
            } else {
                secondaryExpertiseArea = nil
                secondaryExpertiseConfig.text = "Select your professional interests"
            }
        }
        self.primaryExpertiseArea = expertise
        primaryExpertiseConfig.text = expertise
    }
    
    func selectSecondaryExpertise(_ expertise: String) {
        guard expertise != primaryExpertiseArea else { return }
        self.secondaryExpertiseArea = expertise
        secondaryExpertiseConfig.text = expertise
    }
    
    func clearCountry() {
        country = nil
        countryConfig.text = "Select your country"
    }
    
    func clearPrimaryExpertise() {
        primaryExpertiseArea = nil
        primaryExpertiseConfig.text = "Select your professional interests"
    }
    
    func clearSecondaryExpertise() {
        secondaryExpertiseArea = nil
        secondaryExpertiseConfig.text = "Select your professional interests"
    }
    
    func submitRegistration() async -> Bool {
        validateName()
        
        guard isFormValid, nameError == nil else {
            return false
        }
        
        guard let appleId = authenticationManager?.userIdentifier else {
            errorMessage = "Apple ID not found. Please sign in again."
            return false
        }
        
        isLoading = true
        LoaderPresenter.shared.show()
        errorMessage = nil
        
        defer {
            isLoading = false
            LoaderPresenter.shared.hide()
        }
        
        do {
            var photoUrl: String?
            if let image = profileImage {
                photoUrl = try await profileImageService.uploadProfileImage(
                    image,
                    appleId: appleId,
                    oldPhotoUrl: nil
                )
            }
            
            var areas: [String] = []
            if let primary = primaryExpertiseArea {
                areas.append(primary)
            }
            if let secondary = secondaryExpertiseArea, secondary != primaryExpertiseArea {
                areas.append(secondary)
            }
            let areasToSave: [String]? = areas.isEmpty ? nil : areas
            
            let user = User(
                id: nil,
                appleId: appleId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                country: country,
                areas: areasToSave,
                interests: nil,
                photoUrl: photoUrl,
                instagramUrl: nil,
                linkedinUrl: nil
            )
            
            let userId = try await userService.createUser(user)
            var savedUser = user
            savedUser.id = userId
            
            ErrorPresenter.shared.dismiss()
            
            authenticationManager?.completeRegistration(user: savedUser)
            
            return true
        } catch {
            errorMessage = "Error saving registration: \(error.localizedDescription)"
            
            if isNetworkError(error) {
                ErrorPresenter.shared.showNetworkError(retry: { [weak self] in
                    Task { @MainActor in
                        _ = await self?.submitRegistration()
                    }
                })
            } else {
                ErrorPresenter.shared.showServiceError(retry: { [weak self] in
                    Task { @MainActor in
                        _ = await self?.submitRegistration()
                    }
                })
            }
            
            return false
        }
    }
    
    private func isNetworkError(_ error: Error) -> Bool {
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
                if nsError.code == 14 || nsError.code == 4 {
                    return true
                }
            }
            
            let errorMessage = nsError.localizedDescription.lowercased()
            let networkKeywords = ["network", "connection", "internet", "conexión", "red", "conectividad", "timeout", "unreachable"]
            if networkKeywords.contains(where: errorMessage.contains) {
                return true
            }
        }
        
        return false
    }
    
    func clearError() {
        errorMessage = nil
    }
}
