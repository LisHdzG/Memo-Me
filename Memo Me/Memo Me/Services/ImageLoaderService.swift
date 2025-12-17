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
        cache.totalCostLimit = 50 * 1024 * 1024
        return cache
    }()
    
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    private var cachedKeys: Set<String> = []
    
    private init() {}
    
    func loadImage(from urlString: String?) async -> UIImage? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }
        
        let cacheKey = NSString(string: urlString)
        
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        if let existingTask = loadingTasks[urlString] {
            return await existingTask.value
        }
        
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
                
                let cost = data.count
                self.imageCache.setObject(image, forKey: cacheKey, cost: cost)
                
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
        
        imageCache.removeObject(forKey: cacheKey)
        
        cachedKeys.remove(urlString)
        
        if let task = loadingTasks[urlString] {
            task.cancel()
            loadingTasks.removeValue(forKey: urlString)
        }
    }
    
    func invalidateImages(containing pattern: String) {
        let keysToRemove = cachedKeys.filter { $0.contains(pattern) }
        
        for key in keysToRemove {
            let cacheKey = NSString(string: key)
            imageCache.removeObject(forKey: cacheKey)
            cachedKeys.remove(key)
        }
        
        let tasksToCancel = loadingTasks.filter { $0.key.contains(pattern) }
        for (url, task) in tasksToCancel {
            task.cancel()
            loadingTasks.removeValue(forKey: url)
        }
    }
}
