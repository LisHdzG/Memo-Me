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
    
    @State private var privateSpaceCode: String = ""
    @State private var showQRScanner = false
    @State private var scannedCode: String?
    @State private var cameraPermissionDenied = false
    @State private var showPermissionAlert = false
    
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
                
                if viewModel.isLoading && viewModel.publicSpaces.isEmpty && viewModel.userSpaces.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Cargando espacios...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Sección: Unirse a espacio por código
                            JoinPrivateSpaceSection(
                                code: $privateSpaceCode,
                                onJoin: {
                                    if let userId = authManager.currentUser?.id {
                                        Task {
                                            if let joinedSpace = await viewModel.joinSpaceByCode(code: privateSpaceCode, userId: userId) {
                                                spaceSelectionService.saveSelectedSpace(joinedSpace)
                                                privateSpaceCode = ""
                                            }
                                        }
                                    }
                                },
                                onScanQR: {
                                    showQRScanner = true
                                },
                                isJoining: viewModel.isJoiningPrivateSpace
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Sección: Espacios a los que perteneces
                            if !viewModel.userSpaces.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Espacios a los que perteneces")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                    
                                    LazyVStack(spacing: 16) {
                                        ForEach(viewModel.userSpaces) { space in
                                            if let userId = authManager.currentUser?.id {
                                                SpaceCardView(
                                                    space: space,
                                                    isMember: true,
                                                    onJoin: {},
                                                    onView: {
                                                        spaceSelectionService.saveSelectedSpace(space)
                                                    },
                                                    isJoining: false
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // Sección: Espacios públicos
                            if !viewModel.publicSpaces.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Espacios públicos")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                    
                                    LazyVStack(spacing: 16) {
                                        ForEach(viewModel.publicSpaces) { space in
                                            if let userId = authManager.currentUser?.id {
                                                let isMember = viewModel.isUserMember(space: space, userId: userId)
                                                
                                                SpaceCardView(
                                                    space: space,
                                                    isMember: isMember,
                                                    onJoin: {
                                                        Task {
                                                            await viewModel.joinSpace(space: space, userId: userId)
                                                            await viewModel.refreshSpaces(userId: userId)
                                                            if let updatedSpace = viewModel.publicSpaces.first(where: { $0.spaceId == space.spaceId }) ?? viewModel.userSpaces.first(where: { $0.spaceId == space.spaceId }) {
                                                                spaceSelectionService.saveSelectedSpace(updatedSpace)
                                                            }
                                                        }
                                                    },
                                                    onView: {
                                                        spaceSelectionService.saveSelectedSpace(space)
                                                    },
                                                    isJoining: viewModel.isJoiningSpace
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // Mensaje cuando no hay espacios
                            if viewModel.publicSpaces.isEmpty && viewModel.userSpaces.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "rectangle.3.group")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text("No hay espacios disponibles")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Únete a un espacio público o privado para comenzar")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 40)
                            }
                        }
                        .padding(.bottom, 20)
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
            .sheet(isPresented: $showQRScanner) {
                QRCodeScannerView(
                    scannedCode: $scannedCode,
                    isPresented: $showQRScanner,
                    permissionDenied: $cameraPermissionDenied
                )
            }
            .onChange(of: scannedCode) { oldValue, newValue in
                if let code = newValue {
                    privateSpaceCode = code
                    showQRScanner = false
                }
            }
            .onChange(of: cameraPermissionDenied) { oldValue, newValue in
                if newValue {
                    showPermissionAlert = true
                    cameraPermissionDenied = false
                }
            }
            .alert("Permiso de cámara requerido", isPresented: $showPermissionAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Abrir Configuración") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("Necesitamos acceso a la cámara para escanear códigos QR. Por favor, habilita el permiso de cámara en Configuración.")
            }
        }
        .task {
            if let userId = authManager.currentUser?.id {
                await viewModel.loadSpaces(userId: userId)
            }
        }
    }
}

struct JoinPrivateSpaceSection: View {
    @Binding var code: String
    let onJoin: () -> Void
    let onScanQR: () -> Void
    let isJoining: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Unirse a un espacio")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                TextField("Ingresa el código del espacio (público o privado)", text: $code)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                
                Button(action: onScanQR) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color("PurpleGradientTop"))
                        .cornerRadius(10)
                }
            }
            
            Button(action: onJoin) {
                if isJoining {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Uniéndose...")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("PurpleGradientTop").opacity(0.7))
                    .cornerRadius(10)
                } else {
                    Text("Unirse")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("PurpleGradientTop"))
                        .cornerRadius(10)
                }
            }
            .disabled(code.isEmpty || isJoining)
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

struct QRCodeScannerView: View {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool
    @Binding var permissionDenied: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                QRCodeScanner(
                    scannedCode: $scannedCode,
                    isPresented: $isPresented,
                    permissionDenied: $permissionDenied
                )
                
                VStack {
                    Spacer()
                    Text("Apunta la cámara al código QR")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
            }
            .navigationTitle("Escanear QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct SpaceCardView: View {
    let space: Space
    let isMember: Bool
    let onJoin: () -> Void
    let onView: () -> Void
    let isJoining: Bool
    
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
                    
                    Text("\(space.members.count) miembros")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            if isMember {
                Button(action: onView) {
                    HStack(spacing: 6) {
                        Text("Ver")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
            } else {
                Button(action: onJoin) {
                    if isJoining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Unirse")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("PurpleGradientTop"))
                        .cornerRadius(8)
                    }
                }
                .disabled(isJoining)
            }
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
