//
//  FavoritesView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct FavoritesView: View {
    @State private var favoriteContacts: [Contact] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    
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
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Mis Favoritos")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("\(favoriteContacts.count) favoritos")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Mensaje de error
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                
                // Lista de favoritos
                if !favoriteContacts.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteContacts) { contact in
                                FavoriteContactCard(contact: contact)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                } else if !isLoading {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No tienes favoritos aún")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Agrega contactos a tus favoritos para verlos aquí")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            await loadFavoriteContacts()
        }
    }
    
    /// Carga los contactos favoritos
    private func loadFavoriteContacts() async {
        isLoading = true
        errorMessage = nil
        
        // Por ahora, cargar algunos contactos de ejemplo
        // TODO: Implementar lógica para cargar favoritos desde Firestore
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Placeholder: Usar contactos dummy como ejemplo
            // En el futuro, esto debería cargar solo los contactos marcados como favoritos
            favoriteContacts = []
            isLoading = false
        }
    }
}

// Vista de tarjeta para cada contacto favorito
struct FavoriteContactCard: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 16) {
            // Imagen del contacto
            if let imageName = contact.imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else if let imageUrl = contact.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(contact.name.prefix(1)))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            
            // Información del contacto
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Icono de favorito
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                .foregroundColor(.pink)
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    FavoritesView()
}

