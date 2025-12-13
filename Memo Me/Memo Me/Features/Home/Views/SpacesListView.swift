//
//  SpacesListView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct SpacesListView: View {
    @StateObject private var viewModel = SpacesViewModel()
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
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
                
                if viewModel.isLoading && viewModel.spaces.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Cargando espacios...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else if viewModel.spaces.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No tienes espacios activos")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Únete a un espacio para comenzar")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.spaces) { space in
                                Button(action: {
                                    spaceSelectionService.saveSelectedSpace(space)
                                }) {
                                    SpaceCardView(space: space)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .refreshable {
                        if let userId = authManager.currentUser?.id {
                            await viewModel.refreshSpaces(userId: userId)
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 50)
                    }
                }
            }
            .navigationTitle("Espacios")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if let userId = authManager.currentUser?.id {
                            Task {
                                await viewModel.refreshSpaces(userId: userId)
                            }
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            if let userId = authManager.currentUser?.id {
                await viewModel.loadActiveSpaces(userId: userId)
            }
        }
    }
}

struct SpaceCardView: View {
    let space: Space
    
    var body: some View {
        HStack(spacing: 16) {
            if !space.bannerUrl.isEmpty {
                AsyncImage(url: URL(string: space.bannerUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                    
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(space.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(space.spaceId)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(space.memberIds.count) miembros")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
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
