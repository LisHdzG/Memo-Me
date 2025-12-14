//
//  ProfileImageService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import UIKit
import FirebaseStorage

@MainActor
class ProfileImageService {
    static let shared = ProfileImageService()
    
    private let storage = Storage.storage()
    private let maxImageSize: CGFloat = 500
    private let compressionQuality: CGFloat = 0.7
    
    private init() {}
    
    private func generateFileName(for appleId: String) -> String {
        return "\(appleId).jpg"
    }
    
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size
        
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func getStorageReference(for appleId: String) -> StorageReference {
        let fileName = generateFileName(for: appleId)
        return storage.reference().child("profile_images/\(fileName)")
    }
    
    func uploadProfileImage(_ image: UIImage, appleId: String, oldPhotoUrl: String? = nil) async throws -> String {
        guard let resizedImage = resizeImage(image, maxSize: maxImageSize) else {
            throw NSError(domain: "ProfileImageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error al redimensionar la imagen"])
        }
        
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw NSError(domain: "ProfileImageService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error al convertir la imagen"])
        }
        
        let storageRef = getStorageReference(for: appleId)
        
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
                        continuation.resume(throwing: NSError(domain: "ProfileImageService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la URL de descarga"]))
                        return
                    }
                    
                    if let oldPhotoUrl = oldPhotoUrl {
                        ImageLoaderService.shared.removeImage(from: oldPhotoUrl)
                    }
                    
                    ImageLoaderService.shared.removeImage(from: downloadURL.absoluteString)
                    
                    continuation.resume(returning: downloadURL.absoluteString)
                }
            }
        }
    }
    
    func deleteProfileImage(for appleId: String, photoUrl: String?) async throws {
        guard let photoUrl = photoUrl else { return }
        
        ImageLoaderService.shared.removeImage(from: photoUrl)
        
        let storageRef = getStorageReference(for: appleId)
        try await storageRef.delete()
    }
}
