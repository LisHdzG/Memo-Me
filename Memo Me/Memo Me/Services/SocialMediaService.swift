//
//  SocialMediaService.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import Foundation
import UIKit

@MainActor
class SocialMediaService {
    static let shared = SocialMediaService()
    
    private init() {}
    
    /// Extrae el username de una URL de Instagram
    func extractInstagramUsername(from urlString: String) -> String? {
        let urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Patrones comunes de URLs de Instagram
        let patterns = [
            "instagram.com/([^/?]+)",
            "instagr.am/([^/?]+)",
            "@([a-zA-Z0-9._]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
               let usernameRange = Range(match.range(at: 1), in: urlString) {
                var username = String(urlString[usernameRange])
                // Limpiar el username (remover caracteres especiales)
                username = username.replacingOccurrences(of: "@", with: "")
                return username
            }
        }
        
        // Si no tiene formato de URL, asumir que es el username directamente
        if !urlString.contains("http") && !urlString.contains("www") {
            return urlString.replacingOccurrences(of: "@", with: "")
        }
        
        return nil
    }
    
    /// Extrae el username o ID de una URL de LinkedIn
    func extractLinkedInUsername(from urlString: String) -> String? {
        let urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Patrones comunes de URLs de LinkedIn
        let patterns = [
            "linkedin.com/in/([^/?]+)",
            "linkedin.com/profile/view\\?id=([^&]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
               let usernameRange = Range(match.range(at: 1), in: urlString) {
                return String(urlString[usernameRange])
            }
        }
        
        // Si no tiene formato de URL, asumir que es el username directamente
        if !urlString.contains("http") && !urlString.contains("www") {
            return urlString
        }
        
        return nil
    }
    
    /// Abre Instagram intentando primero la app, luego el navegador
    func openInstagram(urlString: String) {
        guard let username = extractInstagramUsername(from: urlString) else {
            // Si no podemos extraer el username, intentar abrir la URL directamente
            openURL(urlString)
            return
        }
        
        // Intentar abrir en la app de Instagram
        let instagramAppURL = URL(string: "instagram://user?username=\(username)")
        let instagramWebURL = URL(string: "https://instagram.com/\(username)")
        
        if let appURL = instagramAppURL, UIApplication.shared.canOpenURL(appURL) {
            // Abrir en la app
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else if let webURL = instagramWebURL {
            // Abrir en el navegador
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        } else {
            // Fallback: intentar abrir la URL original
            openURL(urlString)
        }
    }
    
    /// Abre LinkedIn intentando primero la app, luego el navegador
    func openLinkedIn(urlString: String) {
        guard let username = extractLinkedInUsername(from: urlString) else {
            // Si no podemos extraer el username, intentar abrir la URL directamente
            openURL(urlString)
            return
        }
        
        // Intentar abrir en la app de LinkedIn
        let linkedInAppURL = URL(string: "linkedin://profile/\(username)")
        let linkedInWebURL = URL(string: "https://linkedin.com/in/\(username)")
        
        if let appURL = linkedInAppURL, UIApplication.shared.canOpenURL(appURL) {
            // Abrir en la app
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else if let webURL = linkedInWebURL {
            // Abrir en el navegador
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        } else {
            // Fallback: intentar abrir la URL original
            openURL(urlString)
        }
    }
    
    /// Abre una URL genérica
    private func openURL(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Asegurar que tenga protocolo
        var finalURL = trimmed
        if !finalURL.hasPrefix("http://") && !finalURL.hasPrefix("https://") {
            finalURL = "https://\(finalURL)"
        }
        
        if let url = URL(string: finalURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    /// Valida y formatea una URL de Instagram
    func formatInstagramURL(_ urlString: String) -> String {
        guard let username = extractInstagramUsername(from: urlString) else {
            return urlString
        }
        return "https://instagram.com/\(username)"
    }
    
    /// Valida y formatea una URL de LinkedIn
    func formatLinkedInURL(_ urlString: String) -> String {
        guard let username = extractLinkedInUsername(from: urlString) else {
            return urlString
        }
        return "https://linkedin.com/in/\(username)"
    }
}
