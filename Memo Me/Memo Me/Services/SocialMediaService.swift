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
    
    func extractInstagramUsername(from urlString: String) -> String? {
        let urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
                username = username.replacingOccurrences(of: "@", with: "")
                return username
            }
        }
        
        if !urlString.contains("http") && !urlString.contains("www") {
            return urlString.replacingOccurrences(of: "@", with: "")
        }
        
        return nil
    }
    
    func extractLinkedInUsername(from urlString: String) -> String? {
        let urlString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        
        if !urlString.contains("http") && !urlString.contains("www") {
            return urlString
        }
        
        return nil
    }
    
    func openInstagram(urlString: String) {
        guard let username = extractInstagramUsername(from: urlString) else {
            openURL(urlString)
            return
        }
        
        let instagramAppURL = URL(string: "instagram://user?username=\(username)")
        let instagramWebURL = URL(string: "https://instagram.com/\(username)")
        
        if let appURL = instagramAppURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else if let webURL = instagramWebURL {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        } else {
            openURL(urlString)
        }
    }
    
    func openLinkedIn(urlString: String) {
        guard let username = extractLinkedInUsername(from: urlString) else {
            openURL(urlString)
            return
        }
        
        let linkedInAppURL = URL(string: "linkedin://profile/\(username)")
        let linkedInWebURL = URL(string: "https://linkedin.com/in/\(username)")
        
        if let appURL = linkedInAppURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        } else if let webURL = linkedInWebURL {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        } else {
            openURL(urlString)
        }
    }
    
    private func openURL(_ urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var finalURL = trimmed
        if !finalURL.hasPrefix("http://") && !finalURL.hasPrefix("https://") {
            finalURL = "https://\(finalURL)"
        }
        
        if let url = URL(string: finalURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func formatInstagramURL(_ urlString: String) -> String {
        guard let username = extractInstagramUsername(from: urlString) else {
            return urlString
        }
        return "https://instagram.com/\(username)"
    }
    
    func formatLinkedInURL(_ urlString: String) -> String {
        guard let username = extractLinkedInUsername(from: urlString) else {
            return urlString
        }
        return "https://linkedin.com/in/\(username)"
    }
}
