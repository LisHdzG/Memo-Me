//
//  ProfileViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI
import PhotosUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profileImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var name: String = ""
    @Published var country: String?
    @Published var selectedAreas: [String] = []
    @Published var selectedInterests: [String] = []
    @Published var instagramUrl: String = ""
    @Published var linkedinUrl: String = ""
    
    // MARK: - Picker Configs
    @Published var countryConfig: PickerConfig = .init(text: "Seleccionar país")
    @Published var areasConfig: PickerConfig = .init(text: "Seleccionar área")
    @Published var interestsConfig: PickerConfig = .init(text: "Seleccionar interés")
    
    // MARK: - State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Original Values (for change detection)
    private var originalName: String = ""
    private var originalCountry: String?
    private var originalAreas: [String] = []
    private var originalInterests: [String] = []
    private var originalPhotoUrl: String?
    private var originalInstagramUsername: String = ""
    private var originalLinkedinUsername: String = ""
    
    // MARK: - Services
    private let userService = UserService()
    private let profileImageService = ProfileImageService.shared
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication Manager
    var authenticationManager: AuthenticationManager?
    
    // MARK: - Computed Properties
    var hasChanges: Bool {
        let nameChanged = name.trimmingCharacters(in: .whitespacesAndNewlines) != originalName.trimmingCharacters(in: .whitespacesAndNewlines)
        let countryChanged = country != originalCountry
        let areasChanged = Set(selectedAreas) != Set(originalAreas)
        let interestsChanged = Set(selectedInterests) != Set(originalInterests)
        let photoChanged = selectedPhotoItem != nil || (profileImage == nil && originalPhotoUrl != nil)
        let instagramChanged = instagramUrl.trimmingCharacters(in: .whitespacesAndNewlines) != originalInstagramUsername
        let linkedinChanged = linkedinUrl.trimmingCharacters(in: .whitespacesAndNewlines) != originalLinkedinUsername
        
        return nameChanged || countryChanged || areasChanged || interestsChanged || photoChanged || instagramChanged || linkedinChanged
    }
    
    // MARK: - Data Sources
    let countries: [String] = [
        "México", "Estados Unidos", "España", "Argentina", "Colombia",
        "Chile", "Perú", "Venezuela", "Ecuador", "Guatemala",
        "Cuba", "Haití", "Bolivia", "República Dominicana", "Honduras",
        "Paraguay", "El Salvador", "Nicaragua", "Costa Rica", "Panamá",
        "Uruguay", "Jamaica", "Trinidad y Tobago", "Guyana", "Surinam",
        "Brasil", "Canadá", "Reino Unido", "Francia", "Alemania",
        "Italia", "Portugal", "Países Bajos", "Bélgica", "Suiza",
        "Austria", "Suecia", "Noruega", "Dinamarca", "Finlandia",
        "Polonia", "Grecia", "Rusia", "China", "Japón",
        "India", "Corea del Sur", "Australia", "Nueva Zelanda", "Sudáfrica"
    ]
    
    let expertiseAreas: [String] = [
        "Desarrollo iOS", "Desarrollo Android", "Desarrollo Web",
        "Backend Development", "Frontend Development", "Full Stack",
        "UI/UX Design", "Diseño Gráfico", "Product Design",
        "Product Management", "Machine Learning", "Data Science",
        "Inteligencia Artificial", "DevOps", "Cloud Computing",
        "Cybersecurity", "Game Development", "AR/VR Development",
        "Blockchain", "Mobile Development", "Desktop Development",
        "Embedded Systems", "QA/Testing", "Project Management",
        "Business Analysis", "Design"
    ]
    
    let interestsOptions: [String] = [
        "Música", "Cine", "Literatura", "Arte", "Fotografía",
        "Cocina", "Deportes", "Viajes", "Tecnología", "Gaming",
        "Fitness", "Yoga", "Meditación", "Painting", "Baking",
        "Pintura", "Jardinería", "Bricolaje", "Escritura", "Baile",
        "Teatro", "Idiomas", "Historia", "Ciencia", "Astronomía", "Naturaleza"
    ]
    
    // MARK: - Initialization
    init() {
        setupPhotoObserver()
    }
    
    // MARK: - Load User Data
    func loadUserData() {
        guard let user = authenticationManager?.currentUser else { return }
        
        originalName = user.name
        originalCountry = user.country
        originalAreas = user.areas ?? []
        originalInterests = user.interests ?? []
        originalPhotoUrl = user.photoUrl
        
        // Guardar los usernames originales (sin URL) para comparación
        if let savedInstagramUrl = user.instagramUrl, !savedInstagramUrl.isEmpty {
            originalInstagramUsername = SocialMediaService.shared.extractInstagramUsername(from: savedInstagramUrl) ?? ""
        } else {
            originalInstagramUsername = ""
        }
        
        if let savedLinkedinUrl = user.linkedinUrl, !savedLinkedinUrl.isEmpty {
            originalLinkedinUsername = SocialMediaService.shared.extractLinkedInUsername(from: savedLinkedinUrl) ?? ""
        } else {
            originalLinkedinUsername = ""
        }
        
        name = user.name
        country = user.country
        
        if let country = country {
            countryConfig.text = country
        } else {
            countryConfig.text = "Seleccionar país"
        }
        
        selectedAreas = user.areas ?? []
        selectedInterests = user.interests ?? []
        
        // Extraer solo el username de las URLs guardadas para mostrar en el campo
        if let savedInstagramUrl = user.instagramUrl, !savedInstagramUrl.isEmpty {
            self.instagramUrl = SocialMediaService.shared.extractInstagramUsername(from: savedInstagramUrl) ?? ""
        } else {
            self.instagramUrl = ""
        }
        
        if let savedLinkedinUrl = user.linkedinUrl, !savedLinkedinUrl.isEmpty {
            self.linkedinUrl = SocialMediaService.shared.extractLinkedInUsername(from: savedLinkedinUrl) ?? ""
        } else {
            self.linkedinUrl = ""
        }
        
        if let photoUrl = user.photoUrl, let url = URL(string: photoUrl) {
            Task {
                await loadImageFromUrl(url)
            }
        }
        
        selectedPhotoItem = nil
    }
    
    private func loadImageFromUrl(_ url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                profileImage = image
            }
        } catch {
            // Failed to load image
        }
    }
    
    // MARK: - Photo Handling
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
    
    // MARK: - Picker Handling
    func selectCountry(_ country: String) {
        self.country = country
        countryConfig.text = country
    }
    
    func clearCountry() {
        country = nil
        countryConfig.text = "Seleccionar país"
    }
    
    func addArea(_ area: String) {
        if !selectedAreas.contains(area) {
            selectedAreas.append(area)
            areasConfig.text = "Seleccionar área"
        }
    }
    
    func removeArea(_ area: String) {
        selectedAreas.removeAll { $0 == area }
    }
    
    func addInterest(_ interest: String) {
        if !selectedInterests.contains(interest) {
            selectedInterests.append(interest)
            interestsConfig.text = "Seleccionar interés"
        }
    }
    
    func removeInterest(_ interest: String) {
        selectedInterests.removeAll { $0 == interest }
    }
    
    // MARK: - Save Profile
    func saveProfile() async -> Bool {
        guard let currentUser = authenticationManager?.currentUser,
              let userId = currentUser.id,
              let appleId = authenticationManager?.userIdentifier else {
            errorMessage = "No se pudo obtener la información del usuario"
            return false
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "El nombre es obligatorio"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            var photoUrl: String? = currentUser.photoUrl
            if let image = profileImage {
                if selectedPhotoItem != nil {
                    // Si hay una foto anterior, se eliminará automáticamente al subir la nueva
                    photoUrl = try await profileImageService.uploadProfileImage(
                        image,
                        appleId: appleId,
                        oldPhotoUrl: currentUser.photoUrl
                    )
                }
            } else if selectedPhotoItem == nil && profileImage == nil {
                // Si se eliminó la foto, borrar la imagen del almacenamiento
                if let oldPhotoUrl = currentUser.photoUrl {
                    try? await profileImageService.deleteProfileImage(for: appleId, photoUrl: oldPhotoUrl)
                }
                photoUrl = nil
            }
            
            let trimmedInstagramUrl = instagramUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedLinkedinUrl = linkedinUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Formatear URLs de Instagram y LinkedIn
            let formattedInstagramUrl: String? = trimmedInstagramUrl.isEmpty ? nil : SocialMediaService.shared.formatInstagramURL(trimmedInstagramUrl)
            let formattedLinkedinUrl: String? = trimmedLinkedinUrl.isEmpty ? nil : SocialMediaService.shared.formatLinkedInURL(trimmedLinkedinUrl)
            
            var updatedUser = User(
                id: userId,
                appleId: appleId,
                name: trimmedName,
                country: country,
                areas: selectedAreas.isEmpty ? nil : selectedAreas,
                interests: selectedInterests.isEmpty ? nil : selectedInterests,
                photoUrl: photoUrl,
                instagramUrl: formattedInstagramUrl,
                linkedinUrl: formattedLinkedinUrl
            )
            
            try await userService.updateUser(updatedUser)
            
            authenticationManager?.updateCachedUser(updatedUser)
            
            originalName = trimmedName
            originalCountry = country
            originalAreas = selectedAreas
            originalInterests = selectedInterests
            originalPhotoUrl = photoUrl
            originalInstagramUsername = trimmedInstagramUrl.isEmpty ? "" : (SocialMediaService.shared.extractInstagramUsername(from: trimmedInstagramUrl) ?? "")
            originalLinkedinUsername = trimmedLinkedinUrl.isEmpty ? "" : (SocialMediaService.shared.extractLinkedInUsername(from: trimmedLinkedinUrl) ?? "")
            selectedPhotoItem = nil
            
            isLoading = false
            successMessage = "Perfil actualizado correctamente"
            
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    successMessage = nil
                }
            }
            
            return true
        } catch {
            isLoading = false
            errorMessage = "Error al actualizar el perfil: \(error.localizedDescription)"
            return false
        }
    }
    
    
    // MARK: - Delete Account
    func deleteAccount() async -> Bool {
        guard let currentUser = authenticationManager?.currentUser,
              let userId = currentUser.id else {
            errorMessage = "No se pudo obtener la información del usuario"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await userService.deleteUser(userId: userId)
            
            authenticationManager?.signOut()
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = "Error al eliminar la cuenta: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}

