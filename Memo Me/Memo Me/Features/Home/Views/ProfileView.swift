//
//  ProfileView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    
    var body: some View {
        ZStack {
            Color(.ghostWhite)
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Toolbar button en la esquina superior
                        HStack {
                            Spacer()
                            
                                Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                showEditProfile = true
                            }
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primaryDark)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                                .shadow(color: .primaryDark.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .scaleEffect(showEditProfile ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showEditProfile)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Foto de perfil
                            let photoUrl = authManager.currentUser?.photoUrl
                    VStack(spacing: 20) {
                            AsyncImageView(
                                imageUrl: photoUrl,
                                placeholderText: userName,
                                contentMode: .fill,
                            size: 140
                            )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.primaryDark.opacity(0.4),
                                            Color.primaryDark.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                        )
                        .shadow(color: .primaryDark.opacity(0.15), radius: 12, x: 0, y: 4)
                            
                            Text(userName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primaryDark)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Información del perfil
                        let country = authManager.currentUser?.country ?? "No especificado"
                    ProfileInfoCard(
                        icon: "globe",
                            title: "País",
                        value: country
                        )
                        .padding(.horizontal, 20)
                    
                        let instagramUrl = authManager.currentUser?.instagramUrl
                        if let url = instagramUrl, !url.isEmpty {
                        ProfileInfoCard(
                            icon: "camera.fill",
                                title: "Instagram",
                            value: url
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    let linkedinUrl = authManager.currentUser?.linkedinUrl
                    if let url = linkedinUrl, !url.isEmpty {
                        ProfileInfoCard(
                            icon: "briefcase.fill",
                            title: "LinkedIn",
                            value: url
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    let areas = authManager.currentUser?.areas ?? []
                    ProfileInfoCardWithTags(
                        icon: "lightbulb.fill",
                        title: "Áreas de Expertise",
                        items: areas.isEmpty ? ["No especificadas"] : areas
                    )
                            .padding(.horizontal, 20)
                    
                    let interests = authManager.currentUser?.interests ?? []
                    ProfileInfoCardWithTags(
                        icon: "heart.fill",
                        title: "Intereses",
                        items: interests.isEmpty ? ["No especificados"] : interests
                    )
                            .padding(.horizontal, 20)
                    
                    // Botones de acción
                        VStack(spacing: 16) {
                            Button(action: {
                                authManager.signOut()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                        .font(.system(size: 18))
                                    Text("Cerrar Sesión")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange.opacity(0.7))
                            .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showDeleteAccountAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 18))
                                    Text("Eliminar Cuenta")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(12)
                        }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 50)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
                .environmentObject(authManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(false)
        }
        .onAppear {
            viewModel.authenticationManager = authManager
        }
        .alert("Eliminar Cuenta", isPresented: $showDeleteAccountAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
        } message: {
            Text("¿Estás seguro de que deseas eliminar tu cuenta? Esta acción es permanente y se perderán todos tus datos. No podrás recuperar tu cuenta después.")
        }
        .overlay {
            if viewModel.isLoading {
                LoaderView()
            }
        }
    }
    
    private var userName: String {
        authManager.currentUser?.name ?? authManager.userName ?? "Usuario"
    }
    
    
}

struct ProfileInfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryDark.opacity(0.8))
                    .frame(width: 28, height: 28)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.7))
            }
            
            Text(value)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.primaryDark)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.4))
                        .shadow(color: .primaryDark.opacity(0.08), radius: 8, x: 0, y: 2)
                )
        }
        .padding(.vertical, 4)
    }
}

struct ProfileInfoCardWithTags: View {
    let icon: String
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primaryDark.opacity(0.8))
                    .frame(width: 28, height: 28)
                
            Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.7))
            }
            
            if items.isEmpty || (items.count == 1 && (items.first == "No especificadas" || items.first == "No especificados")) {
                Text(items.first ?? "No especificado")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.6))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.4))
                            .shadow(color: .primaryDark.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
            } else {
                FlowLayout(spacing: 10) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.primaryDark)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.5),
                                                Color.white.opacity(0.3)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.primaryDark.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.4))
                        .shadow(color: .primaryDark.opacity(0.08), radius: 8, x: 0, y: 2)
                )
            }
        }
        .padding(.vertical, 4)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
