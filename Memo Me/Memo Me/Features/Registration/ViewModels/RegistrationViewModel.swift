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
    
    @Published var countryConfig: PickerConfig = .init(text: String(localized: "registration.select.country", comment: "Select country placeholder"))
    @Published var primaryExpertiseConfig: PickerConfig = .init(text: String(localized: "registration.select.interests", comment: "Select interests placeholder"))
    @Published var secondaryExpertiseConfig: PickerConfig = .init(text: String(localized: "registration.select.interests", comment: "Select interests placeholder"))
    
    @Published var nameError: String?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userService = UserService()
    private let profileImageService = ProfileImageService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    var authenticationManager: AuthenticationManager?
    
    var countries: [String] {
        let unsortedCountries = [
            "中国", "भारत", "United States", "Indonesia", "پاکستان",
            "Brasil", "বাংলাদেশ", "Nigeria", "Россия", "México",
            "日本", "Pilipinas", "ኢትዮጵያ", "مصر", "Việt Nam", "ایران", "Türkiye", "Deutschland", "ประเทศไทย",
            "United Kingdom", "France", "Italia", "Tanzania", "South Africa",
            "မြန်မာ", "Kenya", "대한민국", "Colombia", "España",
            "Uganda", "Argentina", "الجزائر", "السودان", "Україна",
            "العراق", "افغانستان", "Polska", "Canada", "المغرب",
            "السعودية", "Oʻzbekiston", "Perú", "Angola", "Malaysia",
            "Moçambique", "Ghana", "اليمن", "नेपाल", "Venezuela",
            "Madagasikara", "Cameroun", "Côte d'Ivoire", "조선민주주의인민공화국", "Australia"
        ]
        return unsortedCountries.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    var notInListCountry: String {
        String(localized: "picker.not.in.list", comment: "Not in list option")
    }
    
    var expertiseAreas: [String] {
        let areas = [
            String(localized: "area.ios.development", comment: "iOS Development"),
            String(localized: "area.android.development", comment: "Android Development"),
            String(localized: "area.web.development", comment: "Web Development"),
            String(localized: "area.backend.development", comment: "Backend Development"),
            String(localized: "area.frontend.development", comment: "Frontend Development"),
            String(localized: "area.full.stack", comment: "Full Stack Development"),
            String(localized: "area.ui.ux.design", comment: "UI/UX Design"),
            String(localized: "area.graphic.design", comment: "Graphic Design"),
            String(localized: "area.product.design", comment: "Product Design"),
            String(localized: "area.machine.learning", comment: "Machine Learning"),
            String(localized: "area.data.science", comment: "Data Science"),
            String(localized: "area.artificial.intelligence", comment: "Artificial Intelligence"),
            String(localized: "area.devops", comment: "DevOps"),
            String(localized: "area.cloud.computing", comment: "Cloud Computing"),
            String(localized: "area.cybersecurity", comment: "Cybersecurity"),
            String(localized: "area.game.development", comment: "Game Development"),
            String(localized: "area.qa.testing", comment: "QA/Testing"),
            String(localized: "area.project.management", comment: "Project Management"),
            String(localized: "area.business.analysis", comment: "Business Analysis"),
            String(localized: "area.mobile.development", comment: "Mobile Development"),
            String(localized: "area.database.administration", comment: "Database Administration"),
            String(localized: "area.software.architecture", comment: "Software Architecture"),
            String(localized: "area.system.administration", comment: "System Administration"),
            String(localized: "area.network.engineering", comment: "Network Engineering"),
            String(localized: "area.embedded.systems", comment: "Embedded Systems"),
            String(localized: "area.blockchain", comment: "Blockchain"),
            String(localized: "area.ar.vr.development", comment: "AR/VR Development"),
            String(localized: "area.desktop.development", comment: "Desktop Development"),
            String(localized: "area.digital.marketing", comment: "Digital Marketing"),
            String(localized: "area.content.creation", comment: "Content Creation"),
            String(localized: "area.social.media.management", comment: "Social Media Management"),
            String(localized: "area.video.production", comment: "Video Production"),
            String(localized: "area.photography", comment: "Photography"),
            String(localized: "area.writing.editing", comment: "Writing & Editing"),
            String(localized: "area.translation", comment: "Translation"),
            String(localized: "area.finance.accounting", comment: "Finance & Accounting"),
            String(localized: "area.human.resources", comment: "Human Resources"),
            String(localized: "area.legal", comment: "Legal"),
            String(localized: "area.consulting", comment: "Consulting"),
            String(localized: "area.education", comment: "Education"),
            String(localized: "area.research", comment: "Research"),
            String(localized: "area.healthcare", comment: "Healthcare"),
            String(localized: "area.engineering", comment: "Engineering"),
            String(localized: "area.architecture", comment: "Architecture"),
            String(localized: "area.sales", comment: "Sales"),
            String(localized: "area.customer.service", comment: "Customer Service"),
            String(localized: "area.operations", comment: "Operations"),
            String(localized: "area.logistics", comment: "Logistics"),
            String(localized: "area.supply.chain", comment: "Supply Chain"),
            String(localized: "area.quality.assurance", comment: "Quality Assurance"),
            String(localized: "area.automation", comment: "Automation"),
            String(localized: "area.robotics", comment: "Robotics"),
            String(localized: "area.iot", comment: "Internet of Things (IoT)"),
            String(localized: "area.big.data", comment: "Big Data"),
            String(localized: "area.business.intelligence", comment: "Business Intelligence"),
            String(localized: "area.analytics", comment: "Analytics"),
            String(localized: "area.ecommerce", comment: "E-commerce"),
            String(localized: "area.product.management", comment: "Product Management"),
            String(localized: "area.agile.scrum", comment: "Agile/Scrum"),
            String(localized: "area.api.development", comment: "API Development"),
            String(localized: "area.microservices", comment: "Microservices"),
            String(localized: "area.serverless", comment: "Serverless")
        ]
        return areas.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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
            nameError = String(localized: "registration.error.name.required", comment: "Name required error")
        } else if trimmedName.count < 2 {
            nameError = String(localized: "registration.error.name.min", comment: "Name minimum length error")
        } else if trimmedName.count > 50 {
            nameError = String(localized: "registration.error.name.max", comment: "Name maximum length error")
        } else {
            nameError = nil
        }
    }
    
    func selectCountry(_ country: String) {
        self.country = country
        countryConfig.text = country
    }
    
    func selectPrimaryExpertise(_ expertise: String) {
        // Si ya está seleccionada como secundaria, intercambiar
        if secondaryExpertiseArea == expertise {
            if let oldPrimary = primaryExpertiseArea {
                secondaryExpertiseArea = oldPrimary
                secondaryExpertiseConfig.text = oldPrimary
            } else {
                secondaryExpertiseArea = nil
                secondaryExpertiseConfig.text = String(localized: "registration.select.interests", comment: "Select interests placeholder")
            }
        }
        self.primaryExpertiseArea = expertise
        primaryExpertiseConfig.text = expertise
    }
    
    func selectSecondaryExpertise(_ expertise: String) {
        // No permitir seleccionar la misma que la principal
        guard expertise != primaryExpertiseArea else { return }
        self.secondaryExpertiseArea = expertise
        secondaryExpertiseConfig.text = expertise
    }
    
    func clearCountry() {
        country = nil
        countryConfig.text = String(localized: "registration.select.country", comment: "Select country placeholder")
    }
    
    func clearPrimaryExpertise() {
        primaryExpertiseArea = nil
        primaryExpertiseConfig.text = String(localized: "registration.select.interests", comment: "Select interests placeholder")
    }
    
    func clearSecondaryExpertise() {
        secondaryExpertiseArea = nil
        secondaryExpertiseConfig.text = String(localized: "registration.select.interests", comment: "Select interests placeholder")
    }
    
    func submitRegistration() async -> Bool {
        validateName()
        
        guard isFormValid, nameError == nil else {
            return false
        }
        
        guard let appleId = authenticationManager?.userIdentifier else {
            errorMessage = String(localized: "registration.error.apple.id", comment: "Apple ID not found error")
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
            
            // Si hay un error mostrado, lo ocultamos al tener éxito
            ErrorPresenter.shared.dismiss()
            
            authenticationManager?.completeRegistration(user: savedUser)
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = String(localized: "registration.error.save", comment: "Save error") + ": \(error.localizedDescription)"
            
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
