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
    @Published var expertiseArea: String?
    
    @Published var countryConfig: PickerConfig = .init(text: "Seleccionar país")
    @Published var expertiseConfig: PickerConfig = .init(text: "Seleccionar área")
    
    @Published var nameError: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userService = UserService()
    private let profileImageService = ProfileImageService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    var authenticationManager: AuthenticationManager?
    
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
        "Machine Learning", "Data Science", "Inteligencia Artificial",
        "DevOps", "Cloud Computing", "Cybersecurity",
        "Game Development", "AR/VR Development", "Blockchain",
        "Mobile Development", "Desktop Development", "Embedded Systems",
        "QA/Testing", "Project Management", "Business Analysis"
    ]
    
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
            nameError = "El nombre es obligatorio"
        } else if trimmedName.count < 2 {
            nameError = "El nombre debe tener al menos 2 caracteres"
        } else if trimmedName.count > 50 {
            nameError = "El nombre no puede exceder 50 caracteres"
        } else {
            nameError = nil
        }
    }
    
    func selectCountry(_ country: String) {
        self.country = country
        countryConfig.text = country
    }
    
    func selectExpertise(_ expertise: String) {
        self.expertiseArea = expertise
        expertiseConfig.text = expertise
    }
    
    func clearCountry() {
        country = nil
        countryConfig.text = "Seleccionar país"
    }
    
    func clearExpertise() {
        expertiseArea = nil
        expertiseConfig.text = "Seleccionar área"
    }
    
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
            var photoUrl: String?
            if let image = profileImage {
                photoUrl = try await profileImageService.uploadProfileImage(
                    image,
                    appleId: appleId,
                    oldPhotoUrl: nil
                )
            }
            
            var areas: [String]?
            if let expertise = expertiseArea {
                areas = [expertise]
            }
            
            let user = User(
                id: nil,
                appleId: appleId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                country: country,
                areas: areas,
                interests: nil,
                photoUrl: photoUrl,
                instagramUrl: nil,
                linkedinUrl: nil
            )
            
            let userId = try await userService.createUser(user)
            var savedUser = user
            savedUser.id = userId
            
            // Si hay un error mostrado, lo ocultamos al tener éxito
            ErrorPresenter.shared.dismiss()
            
            authenticationManager?.completeRegistration(user: savedUser)
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = "Error al guardar el registro: \(error.localizedDescription)"
            
            // Determinar si es error de red o del servicio y mostrar la vista apropiada
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
    
    /// Detecta si un error es de red
    private func isNetworkError(_ error: Error) -> Bool {
        // Verificar errores de URLSession (URLError)
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
        
        // Verificar errores de Firebase Firestore relacionados con red
        if let nsError = error as NSError? {
            // Códigos de error de Firestore relacionados con red
            let firestoreErrorDomain = "FIRFirestoreErrorDomain"
            if nsError.domain == firestoreErrorDomain {
                // Código 14 = UNAVAILABLE (servicio no disponible, generalmente por red)
                // Código 4 = DEADLINE_EXCEEDED (timeout, puede ser por red)
                if nsError.code == 14 || nsError.code == 4 {
                    return true
                }
            }
            
            // Verificar si el mensaje de error contiene palabras clave de red
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
