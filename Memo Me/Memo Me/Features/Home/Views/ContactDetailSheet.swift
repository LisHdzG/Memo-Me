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
    @State private var isFavorite: Bool
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    
    private let favoriteService = FavoriteService.shared
    
    init(user: User? = nil, contact: Contact, spaceId: String? = nil) {
        self.user = user
        self.contact = contact
        self.spaceId = spaceId
        // Inicializar isFavorite basado en el estado actual
        let currentSpaceId = spaceId ?? SpaceSelectionService.shared.selectedSpace?.spaceId
        _isFavorite = State(initialValue: FavoriteService.shared.isFavorite(
            contactId: contact.userId ?? contact.id.uuidString,
            for: currentSpaceId
        ))
    }
    
    var displayName: String {
        user?.name ?? contact.name
    }
    
    var photoUrl: String? {
        user?.photoUrl ?? contact.imageUrl
    }
    
    var body: some View {
        ZStack {
            // Fondo con gradiente
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
                    // Header con botones de cerrar y favorito
                    HStack {
                        Spacer()
                        
                        // Botón de favorito
                        Button(action: {
                            let currentSpaceId = spaceId ?? spaceSelectionService.selectedSpace?.spaceId
                            let contactId = contact.userId ?? contact.id.uuidString
                            isFavorite = favoriteService.toggleFavorite(
                                contactId: contactId,
                                for: currentSpaceId
                            )
                            // Notificar cambio en favoritos
                            NotificationCenter.default.post(name: NSNotification.Name("FavoritesChanged"), object: nil)
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 30))
                                .foregroundColor(isFavorite ? .pink : .white.opacity(0.8))
                        }
                        
                        // Botón de cerrar
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
                    
                    // Foto de perfil
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
                    
                    // Información del usuario (solo si tenemos el usuario completo)
                    if let user = user {
                        VStack(spacing: 20) {
                            // Nacionalidad
                            if let nationality = user.nationality, !nationality.isEmpty {
                                InfoRow(
                                    title: "Nacionalidad",
                                    value: nationality,
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
                            
                            // Si no hay información adicional, mostrar mensaje
                            if (user.nationality == nil || user.nationality?.isEmpty == true) &&
                               (user.areas == nil || user.areas?.isEmpty == true) &&
                               (user.interests == nil || user.interests?.isEmpty == true) {
                                InfoMessage(
                                    message: "Este contacto aún no ha completado su perfil",
                                    icon: "info.circle.fill"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    } else {
                        // Si no tenemos el usuario completo, mostrar mensaje
                        InfoMessage(
                            message: "Información completa no disponible",
                            icon: "exclamationmark.circle.fill"
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Spacer para asegurar que el contenido llegue hasta abajo
                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            print("DEBUG ContactDetailSheet body onAppear - displayName: \(displayName), photoUrl: \(photoUrl ?? "nil")")
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

