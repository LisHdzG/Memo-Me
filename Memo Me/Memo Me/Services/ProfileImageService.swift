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
    private let maxImageSize: CGFloat = 500 // Tamaño máximo en píxeles
    private let compressionQuality: CGFloat = 0.7 // Calidad de compresión
    
    private init() {}
    
    /// Genera un nombre de archivo corto basado en el appleId
    private func generateFileName(for appleId: String) -> String {
        // Usar solo el appleId como nombre, sin UUID
        // Esto asegura que siempre se sobrescriba la misma imagen
        return "\(appleId).jpg"
    }
    
    /// Redimensiona una imagen manteniendo su aspecto
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage? {
        let size = image.size
        
        // Si la imagen ya es más pequeña que el tamaño máximo, no redimensionar
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        // Calcular el nuevo tamaño manteniendo el aspecto
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        // Redimensionar la imagen
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Obtiene la referencia de almacenamiento para la imagen de un usuario
    private func getStorageReference(for appleId: String) -> StorageReference {
        let fileName = generateFileName(for: appleId)
        return storage.reference().child("profile_images/\(fileName)")
    }
    
    /// Sube una imagen de perfil, sobrescribiendo la anterior si existe
    func uploadProfileImage(_ image: UIImage, appleId: String, oldPhotoUrl: String? = nil) async throws -> String {
        // Redimensionar la imagen antes de subirla
        guard let resizedImage = resizeImage(image, maxSize: maxImageSize) else {
            throw NSError(domain: "ProfileImageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error al redimensionar la imagen"])
        }
        
        // Convertir a JPEG con compresión
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw NSError(domain: "ProfileImageService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error al convertir la imagen"])
        }
        
        let storageRef = getStorageReference(for: appleId)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Subir la nueva imagen (sobrescribirá la anterior si existe)
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
                    
                    // Invalidar el caché de la imagen anterior si existe
                    if let oldPhotoUrl = oldPhotoUrl {
                        ImageLoaderService.shared.removeImage(from: oldPhotoUrl)
                    }
                    
                    // Invalidar el caché de la nueva imagen también para forzar recarga
                    ImageLoaderService.shared.removeImage(from: downloadURL.absoluteString)
                    
                    continuation.resume(returning: downloadURL.absoluteString)
                }
            }
        }
    }
    
    /// Elimina la imagen de perfil de un usuario
    func deleteProfileImage(for appleId: String, photoUrl: String?) async throws {
        guard let photoUrl = photoUrl else { return }
        
        // Invalidar el caché
        ImageLoaderService.shared.removeImage(from: photoUrl)
        
        // Eliminar del almacenamiento
        let storageRef = getStorageReference(for: appleId)
        try await storageRef.delete()
    }
}
