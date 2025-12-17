//
//  CreateSpaceViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI
import PhotosUI
import Combine
import FirebaseStorage

@MainActor
class CreateSpaceViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var bannerImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var isPublic: Bool = true
    @Published var selectedTypes: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var nameError: String?
    
    let availableTypes: [String] = [
        "Work",
        "Personal",
        "Study",
        "Social",
        "Sports",
        "Art",
        "Technology",
        "Education",
        "Travel",
        "Music",
        "Food",
        "Health",
        "Business",
        "Entertainment",
        "Gaming",
        "Community",
        "Family",
        "Friends"
    ]
    
    private let spaceService = SpaceService()
    private let storage = Storage.storage()
    
    private var cancellables = Set<AnyCancellable>()
    
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
                    self.bannerImage = image
                    self.isLoading = false
                } else {
                    self.errorMessage = "No se pudo cargar la imagen"
                    self.isLoading = false
                }
            } else {
                self.errorMessage = "Error al procesar la imagen"
                self.isLoading = false
            }
        } catch {
            self.errorMessage = "Error: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func removePhoto() {
        bannerImage = nil
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
    
    func createSpace(userId: String) async -> Space? {
        validateName()
        
        guard nameError == nil else {
            return nil
        }
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            nameError = "Name is required"
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let code = spaceService.generateCode(from: trimmedName)
            let spaceId = try await spaceService.generateUniqueSpaceId()
            
            var bannerUrl: String = ""
            if let image = bannerImage {
                bannerUrl = try await uploadBannerImage(image, spaceId: spaceId)
            }
            
            let userReference = "users/\(userId)"
            
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            let typesArray = Array(selectedTypes)
            
            let space = Space(
                id: nil,
                spaceId: spaceId,
                name: trimmedName,
                description: trimmedDescription,
                bannerUrl: bannerUrl,
                members: [userReference],
                isPublic: isPublic,
                isOfficial: false,
                code: code,
                owner: userReference,
                types: typesArray
            )
            
            let spaceDocumentId = try await spaceService.createSpace(space)
            var createdSpace = space
            createdSpace.id = spaceDocumentId
            
            isLoading = false
            return createdSpace
        } catch {
            isLoading = false
            errorMessage = "Failed to create space: \(error.localizedDescription)"
            return nil
        }
    }
    
    private func uploadBannerImage(_ image: UIImage, spaceId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "CreateSpaceViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }
        
        let fileName = "\(spaceId)_\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("space_banners/\(fileName)")
        
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
                        continuation.resume(throwing: NSError(domain: "CreateSpaceViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not get download URL"]))
                        return
                    }
                    
                    continuation.resume(returning: downloadURL.absoluteString)
                }
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func reset() {
        name = ""
        description = ""
        bannerImage = nil
        selectedPhotoItem = nil
        isPublic = true
        selectedTypes = []
        nameError = nil
        errorMessage = nil
    }
}
