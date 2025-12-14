//
//  ImageLoaderService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import UIKit

@MainActor
class ImageLoaderService {
    static let shared = ImageLoaderService()
    
    private var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return cache
    }()
    
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    private var cachedKeys: Set<String> = [] // Rastrear las claves en el caché
    
    private init() {}
    
    func loadImage(from urlString: String?) async -> UIImage? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }
        
        let cacheKey = NSString(string: urlString)
        
        // Verificar caché primero
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Si ya hay una tarea de carga en curso, esperar a que termine
        if let existingTask = loadingTasks[urlString] {
            return await existingTask.value
        }
        
        // Crear nueva tarea de carga
        let task = Task<UIImage?, Never> {
            defer {
                Task { @MainActor in
                    self.loadingTasks.removeValue(forKey: urlString)
                }
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    return nil
                }
                
                guard let image = UIImage(data: data) else {
                    return nil
                }
                
                // Guardar en caché
                let cost = data.count
                self.imageCache.setObject(image, forKey: cacheKey, cost: cost)
                
                // Registrar la clave
                Task { @MainActor in
                    self.cachedKeys.insert(urlString)
                }
                
                return image
            } catch {
                return nil
            }
        }
        
        loadingTasks[urlString] = task
        return await task.value
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
        cachedKeys.removeAll()
    }
    
    func removeImage(from urlString: String?) {
        guard let urlString = urlString else { return }
        let cacheKey = NSString(string: urlString)
        
        // Remover del caché
        imageCache.removeObject(forKey: cacheKey)
        
        // Remover de las claves registradas
        cachedKeys.remove(urlString)
        
        // Cancelar cualquier tarea de carga en curso para esta URL
        if let task = loadingTasks[urlString] {
            task.cancel()
            loadingTasks.removeValue(forKey: urlString)
        }
    }
    
    /// Invalida todas las imágenes que contengan un patrón específico en su URL
    /// Útil para invalidar imágenes de perfil cuando se actualiza la foto de un usuario
    func invalidateImages(containing pattern: String) {
        // Buscar y remover todas las URLs que contengan el patrón
        let keysToRemove = cachedKeys.filter { $0.contains(pattern) }
        
        for key in keysToRemove {
            let cacheKey = NSString(string: key)
            imageCache.removeObject(forKey: cacheKey)
            cachedKeys.remove(key)
        }
        
        // Cancelar tareas de carga que contengan el patrón
        let tasksToCancel = loadingTasks.filter { $0.key.contains(pattern) }
        for (url, task) in tasksToCancel {
            task.cancel()
            loadingTasks.removeValue(forKey: url)
        }
    }
}