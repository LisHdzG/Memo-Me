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
    @State private var selectedContact: Contact?
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
                        Text("\(viewModel.favoriteContacts.count) favoritos")
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
                
                if !viewModel.favoriteContacts.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.favoriteContacts) { contact in
                                FavoriteContactCard(
                                    contact: contact,
                                    onTap: {
                                        selectedContact = contact
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
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
            viewModel.currentUserId = authManager.currentUser?.id
            await viewModel.loadFavoriteContacts(for: spaceSelectionService.selectedSpace)
        }
        .onChange(of: spaceSelectionService.selectedSpace) { oldValue, newValue in
            Task {
                await viewModel.loadFavoriteContacts(for: newValue)
            }
        }
        .onChange(of: authManager.currentUser?.id) { oldValue, newValue in
            viewModel.currentUserId = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FavoritesChanged"))) { _ in
            Task {
                await viewModel.refreshFavorites(for: spaceSelectionService.selectedSpace)
            }
        }
        .sheet(item: $selectedContact) { contact in
            let user = viewModel.getUser(for: contact)
            ContactDetailSheet(
                user: user,
                contact: contact,
                spaceId: spaceSelectionService.selectedSpace?.spaceId
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct FavoriteContactCard: View {
    let contact: Contact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                AsyncImageView(
                    imageUrl: contact.imageUrl,
                    placeholderText: contact.name,
                    contentMode: .fill,
                    size: 60
                )
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
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
    }
}
