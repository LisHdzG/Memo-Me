//
//  FavoritesView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    @EnvironmentObject var authManager: AuthenticationManager
    
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
            
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        Text("Mis Favoritos")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("\(viewModel.allFavorites.count) favoritos")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                
                if !viewModel.favoriteContactsBySpace.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(viewModel.spaceNames, id: \.self) { spaceName in
                                if let favorites = viewModel.favoriteContactsBySpace[spaceName], !favorites.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(spaceName)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                        
                                        LazyVStack(spacing: 16) {
                                            ForEach(favorites) { favoriteContact in
                                                FavoriteContactCard(contact: favoriteContact.contact, spaceName: favoriteContact.spaceName)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                } else if !viewModel.isLoading {
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
            if let userId = authManager.currentUser?.id {
                await viewModel.loadFavoriteContacts(userId: userId)
            }
        }
    }
}

struct FavoriteContactCard: View {
    let contact: Contact
    let spaceName: String
    @State private var showContactDetail: Bool = false
    @State private var user: User?
    
    private let noteService = ContactNoteService.shared
    private let userService = UserService()
    
    var note: String? {
        guard let userId = contact.userId else { return nil }
        return noteService.getNote(contactUserId: userId)
    }
    
    var body: some View {
        Button(action: {
            Task {
                if let userId = contact.userId {
                    user = try? await userService.getUser(userId: userId)
                }
                showContactDetail = true
            }
        }) {
            HStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
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
                    
                    if note != nil {
                        Image(systemName: "note.text")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                            .offset(x: 5, y: -5)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(spaceName)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let note = note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
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
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showContactDetail) {
            ContactDetailSheet(
                user: user,
                contact: contact,
                spaceId: nil
            )
        }
    }
}
