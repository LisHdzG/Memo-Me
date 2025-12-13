//
//  ProfileViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI
import PhotosUI
import Combine
import FirebaseStorage

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profileImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var name: String = ""
    @Published var nationality: String?
    @Published var selectedAreas: [String] = []
    @Published var selectedInterests: [String] = []
    
    // MARK: - Picker Configs
    @Published var nationalityConfig: PickerConfig = .init(text: "Seleccionar nacionalidad")
    @Published var areasConfig: PickerConfig = .init(text: "Seleccionar área")
    @Published var interestsConfig: PickerConfig = .init(text: "Seleccionar interés")
    
    // MARK: - State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - Original Values (for change detection)
    private var originalName: String = ""
    private var originalNationality: String?
    private var originalAreas: [String] = []
    private var originalInterests: [String] = []
    private var originalPhotoUrl: String?
    
    // MARK: - Services
    private let userService = UserService()
    private let storage = Storage.storage()
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication Manager
    var authenticationManager: AuthenticationManager?
    
    // MARK: - Computed Properties
    var hasChanges: Bool {
        let nameChanged = name.trimmingCharacters(in: .whitespacesAndNewlines) != originalName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nationalityChanged = nationality != originalNationality
        let areasChanged = Set(selectedAreas) != Set(originalAreas)
        let interestsChanged = Set(selectedInterests) != Set(originalInterests)
        let photoChanged = selectedPhotoItem != nil || (profileImage == nil && originalPhotoUrl != nil)
        
        return nameChanged || nationalityChanged || areasChanged || interestsChanged || photoChanged
    }
    
    // MARK: - Data Sources
    let nationalities: [String] = [
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
        originalNationality = user.nationality
        originalAreas = user.areas ?? []
        originalInterests = user.interests ?? []
        originalPhotoUrl = user.photoUrl
        
        name = user.name
        nationality = user.nationality
        
        if let nationality = nationality {
            nationalityConfig.text = nationality
        } else {
            nationalityConfig.text = "Seleccionar nacionalidad"
        }
        
        selectedAreas = user.areas ?? []
        selectedInterests = user.interests ?? []
        
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
    func selectNationality(_ nationality: String) {
        self.nationality = nationality
        nationalityConfig.text = nationality
    }
    
    func clearNationality() {
        nationality = nil
        nationalityConfig.text = "Seleccionar nacionalidad"
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
                    photoUrl = try await uploadProfileImage(image, appleId: appleId)
                }
            } else if selectedPhotoItem == nil && profileImage == nil {
                photoUrl = nil
            }
            
            var updatedUser = User(
                id: userId,
                appleId: appleId,
                name: trimmedName,
                nationality: nationality,
                areas: selectedAreas.isEmpty ? nil : selectedAreas,
                interests: selectedInterests.isEmpty ? nil : selectedInterests,
                photoUrl: photoUrl
            )
            
            try await userService.updateUser(updatedUser)
            
            authenticationManager?.updateCachedUser(updatedUser)
            
            originalName = trimmedName
            originalNationality = nationality
            originalAreas = selectedAreas
            originalInterests = selectedInterests
            originalPhotoUrl = photoUrl
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
    
    // MARK: - Photo Upload
    private func uploadProfileImage(_ image: UIImage, appleId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ProfileViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error al convertir la imagen"])
        }
        
        let fileName = "\(appleId)_\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("profile_images/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let downloadURL = url else {
                        continuation.resume(throwing: NSError(domain: "ProfileViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la URL de descarga"]))
                        return
                    }
                    
                    continuation.resume(returning: downloadURL.absoluteString)
                }
            }
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

