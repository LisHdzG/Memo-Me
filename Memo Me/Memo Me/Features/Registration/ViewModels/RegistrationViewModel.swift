//
//  RegistrationViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import PhotosUI
import Combine
import FirebaseStorage

@MainActor
class RegistrationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var profileImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var name: String = ""
    @Published var nationality: String?
    @Published var expertiseArea: String?
    
    // MARK: - Picker Configs
    @Published var nationalityConfig: PickerConfig = .init(text: "Seleccionar nacionalidad")
    @Published var expertiseConfig: PickerConfig = .init(text: "Seleccionar área")
    
    // MARK: - Validation & Errors
    @Published var nameError: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let userService = UserService()
    private let storage = Storage.storage()
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication Manager
    var authenticationManager: AuthenticationManager?
    
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
        "Machine Learning", "Data Science", "Inteligencia Artificial",
        "DevOps", "Cloud Computing", "Cybersecurity",
        "Game Development", "AR/VR Development", "Blockchain",
        "Mobile Development", "Desktop Development", "Embedded Systems",
        "QA/Testing", "Project Management", "Business Analysis"
    ]
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    init() {
        setupPhotoObserver()
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
    
    // MARK: - Validation
    func validateName() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            nameError = "El nombre es obligatorio"
        } else if trimmedName.count < 2 {
            nameError = "El nombre debe tener al menos 2 caracteres"
        } else if trimmedName.count > 50 {
            nameError = "El nombre no puede exceder 50 caracteres"
        } else {
            nameError = nil
        }
    }
    
    // MARK: - Picker Handling
    func selectNationality(_ nationality: String) {
        self.nationality = nationality
        nationalityConfig.text = nationality
    }
    
    func selectExpertise(_ expertise: String) {
        self.expertiseArea = expertise
        expertiseConfig.text = expertise
    }
    
    func clearNationality() {
        nationality = nil
        nationalityConfig.text = "Seleccionar nacionalidad"
    }
    
    func clearExpertise() {
        expertiseArea = nil
        expertiseConfig.text = "Seleccionar área"
    }
    
    // MARK: - Form Submission
    func submitRegistration() async -> Bool {
        validateName()
        
        guard isFormValid, nameError == nil else {
            return false
        }
        
        guard let appleId = authenticationManager?.userIdentifier else {
            errorMessage = "No se encontró el ID de Apple. Por favor, inicia sesión nuevamente."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Subir foto de perfil si existe
            var photoUrl: String? = nil
            if let image = profileImage {
                photoUrl = try await uploadProfileImage(image, appleId: appleId)
            }
            
            // 2. Preparar áreas (si se seleccionó expertiseArea)
            var areas: [String]? = nil
            if let expertise = expertiseArea {
                areas = [expertise]
            }
            
            // 3. Crear el usuario
            let user = User(
                id: nil,
                appleId: appleId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                nationality: nationality,
                areas: areas,
                interests: nil,
                photoUrl: photoUrl
            )
            
            // 4. Guardar en Firestore
            let userId = try await userService.createUser(user)
            var savedUser = user
            savedUser.id = userId
            
            // 5. Notificar al AuthenticationManager
            authenticationManager?.completeRegistration(user: savedUser)
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = "Error al guardar el registro: \(error.localizedDescription)"
            print("❌ Error al registrar usuario: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Photo Upload
    private func uploadProfileImage(_ image: UIImage, appleId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "RegistrationViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error al convertir la imagen"])
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
                        continuation.resume(throwing: NSError(domain: "RegistrationViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la URL de descarga"]))
                        return
                    }
                    
                    continuation.resume(returning: downloadURL.absoluteString)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}
