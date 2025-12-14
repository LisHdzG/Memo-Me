//
//  ContactDetailSheet.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct ContactDetailSheet: View {
    let user: User?
    let contact: Contact
    let spaceId: String?
    @Environment(\.dismiss) private var dismiss
    
    init(user: User? = nil, contact: Contact, spaceId: String? = nil) {
        self.user = user
        self.contact = contact
        self.spaceId = spaceId
    }
    
    var displayName: String {
        user?.name ?? contact.name
    }
    
    var photoUrl: String? {
        user?.photoUrl ?? contact.imageUrl
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("PurpleGradientTop"),
                    Color("PurpleGradientMiddle"),
                    Color("PurpleGradientBottom")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        AsyncImageView(
                            imageUrl: photoUrl,
                            placeholderText: displayName,
                            contentMode: .fill,
                            size: 140
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        )
                        
                        Text(displayName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    if let user = user {
                        VStack(spacing: 20) {
                            // País
                            if let country = user.country, !country.isEmpty {
                                InfoRow(
                                    title: "País",
                                    value: country,
                                    icon: "flag.fill"
                                )
                            }
                            
                            // Áreas de expertise
                            if let areas = user.areas, !areas.isEmpty {
                                InfoRow(
                                    title: "Áreas de Expertise",
                                    value: areas.joined(separator: ", "),
                                    icon: "briefcase.fill"
                                )
                            }
                            
                            // Intereses
                            if let interests = user.interests, !interests.isEmpty {
                                InfoRow(
                                    title: "Intereses",
                                    value: interests.joined(separator: ", "),
                                    icon: "heart.fill"
                                )
                            }
                            
                            // Instagram
                            if let instagramUrl = user.instagramUrl, !instagramUrl.isEmpty {
                                LinkRow(
                                    title: "Instagram",
                                    value: instagramUrl,
                                    url: instagramUrl,
                                    icon: "camera.fill"
                                )
                            }
                            
                            // LinkedIn
                            if let linkedinUrl = user.linkedinUrl, !linkedinUrl.isEmpty {
                                LinkRow(
                                    title: "LinkedIn",
                                    value: linkedinUrl,
                                    url: linkedinUrl,
                                    icon: "briefcase.fill"
                                )
                            }
                            
                            // Si no hay información adicional, mostrar mensaje
                            if (user.country == nil || user.country?.isEmpty == true) &&
                               (user.areas == nil || user.areas?.isEmpty == true) &&
                               (user.interests == nil || user.interests?.isEmpty == true) &&
                               (user.instagramUrl == nil || user.instagramUrl?.isEmpty == true) &&
                               (user.linkedinUrl == nil || user.linkedinUrl?.isEmpty == true) {
                                InfoMessage(
                                    message: "Este contacto aún no ha completado su perfil",
                                    icon: "info.circle.fill"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    } else {
                        InfoMessage(
                            message: "Información completa no disponible",
                            icon: "exclamationmark.circle.fill"
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct LinkRow: View {
    let title: String
    let value: String
    let url: String
    let icon: String
    
    private let socialMediaService = SocialMediaService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Button(action: {
                // Abrir Instagram o LinkedIn según el título
                if title.lowercased().contains("instagram") {
                    socialMediaService.openInstagram(urlString: url)
                } else if title.lowercased().contains("linkedin") {
                    socialMediaService.openLinkedIn(urlString: url)
                } else {
                    // Fallback para otros tipos de enlaces
                    if let urlObj = URL(string: url) {
                        UIApplication.shared.open(urlObj)
                    }
                }
            }) {
                HStack {
                    Text(value)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.blue.opacity(0.9))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                        .foregroundColor(.blue.opacity(0.9))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

struct InfoMessage: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.7))
            
            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

