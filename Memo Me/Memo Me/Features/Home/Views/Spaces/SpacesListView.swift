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
    @Environment(\.dismiss) private var dismiss
    
    let isPresentedAsSheet: Bool
    let shouldDismissOnSelection: Bool
    
    @State private var privateSpaceCode: String = ""
    @State private var showQRScanner = false
    @State private var scannedCode: String?
    @State private var cameraPermissionDenied = false
    @State private var showPermissionAlert = false
    @State private var showCreateSpace = false
    @State private var showJoinConfirmation = false
    @State private var spaceToJoin: Space?
    
    init(isPresentedAsSheet: Bool = false, shouldDismissOnSelection: Bool = false) {
        self.isPresentedAsSheet = isPresentedAsSheet
        self.shouldDismissOnSelection = shouldDismissOnSelection
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.ghostWhite)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("Spaces")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color("DeepSpace"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .background(Color(.ghostWhite))
                    
                    JoinPrivateSpaceSection(
                        code: $privateSpaceCode,
                        onJoin: {
                            if let userId = authManager.currentUser?.id {
                                Task {
                                    if let joinedSpace = await viewModel.joinSpaceByCode(code: privateSpaceCode, userId: userId) {
                                        spaceSelectionService.saveSelectedSpace(joinedSpace)
                                        privateSpaceCode = ""
                                        if shouldDismissOnSelection {
                                            dismiss()
                                        }
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
                    .padding(.bottom, 16)
                    .background(Color(.ghostWhite))
                    
                    if viewModel.isLoading && viewModel.publicSpaces.isEmpty && viewModel.userSpaces.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color("DeepSpace")))
                                .scaleEffect(1.5)
                            
                            Text("Loading spaces...")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.6))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                if !viewModel.userSpaces.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.stack.3d.up.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color("RoyalPurple").opacity(0.8))
                                        
                                        Text("My Spaces")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.primaryDark)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.userSpaces) { space in
                                            SpaceCardView(
                                                space: space,
                                                isMember: true,
                                                onJoin: {},
                                                onView: {
                                                    spaceSelectionService.saveSelectedSpace(space)
                                                    if shouldDismissOnSelection {
                                                        dismiss()
                                                    }
                                                },
                                                isJoining: false
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            if !viewModel.publicSpaces.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "globe")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color("DeepSpace").opacity(0.7))
                                        
                                        Text("Public Spaces")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(.primaryDark)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    LazyVStack(spacing: 16) {
                                        ForEach(viewModel.publicSpaces) { space in
                                            if let currentUserId = authManager.currentUser?.id {
                                                let isMember = viewModel.isUserMember(space: space, userId: currentUserId)
                                                
                                                SpaceCardView(
                                                    space: space,
                                                    isMember: isMember,
                                                    onJoin: {
                                                        spaceToJoin = space
                                                        showJoinConfirmation = true
                                                    },
                                                    onView: {
                                                        spaceSelectionService.saveSelectedSpace(space)
                                                        if shouldDismissOnSelection {
                                                            dismiss()
                                                        }
                                                    },
                                                    isJoining: viewModel.isJoiningSpace
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            if viewModel.publicSpaces.isEmpty && viewModel.userSpaces.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "rectangle.3.group")
                                        .font(.system(size: 60))
                                        .foregroundColor(.primaryDark.opacity(0.3))
                                    
                                    Text("No spaces available")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primaryDark)
                                    
                                    Text("Join a public or private space to get started")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.primaryDark.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 40)
                                .padding(.horizontal, 20)
                            }
                            
                            if !isPresentedAsSheet && !spaceSelectionService.hasContinuedWithoutSpace {
                                VStack(spacing: 4) {
                                    Button(action: {
                                        spaceSelectionService.markAsContinuedWithoutSpace()
                                    }) {
                                        Text("Skip for now")
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color("DeepSpace"))
                                            .underline()
                                    }
                                    
                                    Text("(Enter without space)")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(Color("DeepSpace").opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 20)
                                .padding(.bottom, 40)
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
                }
                
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(.electricRuby).opacity(0.9))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 50)
                            .shadow(color: Color(.electricRuby).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateSpace = true
                    }) {
                        Text("Create Space")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("RoyalPurple"))
                    }
                }
            }
            .sheet(isPresented: $showCreateSpace) {
                CreateSpaceView()
                    .environmentObject(authManager)
                    .onDisappear {
                        if let userId = authManager.currentUser?.id {
                            Task {
                                await viewModel.refreshSpaces(userId: userId)
                            }
                        }
                    }
            }
            .sheet(isPresented: $showQRScanner) {
                QRCodeScannerView(
                    scannedCode: $scannedCode,
                    isPresented: $showQRScanner,
                    permissionDenied: $cameraPermissionDenied
                )
                .environmentObject(authManager)
                .onDisappear {
                    if let userId = authManager.currentUser?.id {
                        Task {
                            await viewModel.refreshSpaces(userId: userId)
                        }
                    }
                }
            }
            .onChange(of: cameraPermissionDenied) { _, newValue in
                if newValue {
                    showPermissionAlert = true
                    cameraPermissionDenied = false
                }
            }
            .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("We need camera access to scan QR codes. Please enable camera permission in Settings.")
            }
            .alert("Join Space", isPresented: $showJoinConfirmation) {
                Button("Cancel", role: .cancel) {
                    spaceToJoin = nil
                }
                Button("Join") {
                    if let space = spaceToJoin, let userId = authManager.currentUser?.id {
                        Task {
                            await viewModel.joinSpace(space: space, userId: userId)
                            await viewModel.refreshSpaces(userId: userId)
                            if let updatedSpace = viewModel.publicSpaces.first(where: { $0.spaceId == space.spaceId }) ?? viewModel.userSpaces.first(where: { $0.spaceId == space.spaceId }) {
                                spaceSelectionService.saveSelectedSpace(updatedSpace)
                                if shouldDismissOnSelection {
                                    dismiss()
                                }
                            }
                            spaceToJoin = nil
                        }
                    }
                }
                .tint(Color("RoyalPurple"))
            } message: {
                if let space = spaceToJoin {
                    Text("Do you want to join \"\(space.name)\"?\n\nOnce you join, members of this space will be able to see your profile.")
                }
            }
        }
        .task {
            if let userId = authManager.currentUser?.id {
                await viewModel.loadSpaces(userId: userId)
            }
        }
        .onDisappear {
            viewModel.stopListeningToSpaces()
        }
    }
}

struct JoinPrivateSpaceSection: View {
    @Binding var code: String
    let onJoin: () -> Void
    let onScanQR: () -> Void
    let isJoining: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Enter space code", text: $code)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(10)
                    .foregroundColor(.primaryDark)
                    .font(.system(size: 14, design: .rounded))
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                
                Button(action: onScanQR) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color("DeepSpace"))
                        .frame(width: 40, height: 40)
                        .background(Color("DeepSpace").opacity(0.1))
                        .cornerRadius(10)
                }
                
                Button(action: onJoin) {
                    if isJoining {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("DeepSpace")))
                            .scaleEffect(0.7)
                            .frame(width: 40, height: 40)
                    } else {
                        Text("Join")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 40)
                            .background(Color("DeepSpace"))
                            .cornerRadius(10)
                    }
                }
                .disabled(code.isEmpty || isJoining)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("DeepSpace").opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct QRCodeScannerView: View {
    @Binding var scannedCode: String?
    @Binding var isPresented: Bool
    @Binding var permissionDenied: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = SpacesViewModel()
    @State private var isJoining = false
    
    var body: some View {
        ZStack {
            QRCodeScanner(
                scannedCode: $scannedCode,
                isPresented: $isPresented,
                permissionDenied: $permissionDenied
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            isPresented = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 20)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 24) {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [10, 8]))
                            .foregroundColor(.white)
                            .frame(width: 250, height: 250)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                    
                                    Text("Scan QR Code")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            )
                        
                        VStack(spacing: 10) {
                            Text("Find or request the QR code of the space you want to join")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.primaryDark)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                            
                            Text("Scan it and you're in!")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("RoyalPurple"))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.95))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color("RoyalPurple").opacity(0.2),
                                                    Color("RoyalPurple").opacity(0.1)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: Color("RoyalPurple").opacity(0.1), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .offset(y: -geometry.size.height * 0.1)
                    
                    Spacer()
                }
            }
            
            if isJoining {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Joining space...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .onChange(of: scannedCode) { _, newValue in
            if let code = newValue, !isJoining {
                Task {
                    await joinSpaceByCode(code: code)
                }
            }
        }
    }
    
    private func joinSpaceByCode(code: String) async {
        guard let userId = authManager.currentUser?.id else { return }
        
        isJoining = true
        
        if let joinedSpace = await viewModel.joinSpaceByCode(code: code, userId: userId) {
            SpaceSelectionService.shared.saveSelectedSpace(joinedSpace)
            isPresented = false
        }
        
        isJoining = false
        scannedCode = nil
    }
}

struct SpaceCardView: View {
    let space: Space
    let isMember: Bool
    let onJoin: () -> Void
    let onView: () -> Void
    let isJoining: Bool
    
    var body: some View {
        Button(action: {
            if isMember {
                onView()
            } else {
                onJoin()
            }
        }) {
            HStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                if !space.bannerUrl.isEmpty {
                    AsyncImage(url: URL(string: space.bannerUrl)) { phase in
                        switch phase {
                        case .empty:
                            placeholderView
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .cornerRadius(12)
                        case .failure:
                            placeholderView
                        @unknown default:
                            placeholderView
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("DeepSpace").opacity(0.1), lineWidth: 1)
                    )
                } else {
                    placeholderView
                }
                
                if space.isOfficial {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("RoyalPurple"))
                        .symbolRenderingMode(.hierarchical)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                        )
                        .offset(x: 4, y: -4)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(space.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryDark)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !space.types.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(space.types.prefix(2), id: \.self) { type in
                            Text(type)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Color("RoyalPurple"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("RoyalPurple").opacity(0.1))
                                .cornerRadius(6)
                        }
                        if space.types.count > 2 {
                            Text("+\(space.types.count - 2)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(Color("RoyalPurple"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("RoyalPurple").opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.primaryDark.opacity(0.5))
                    
                    Text("\(space.members.count) members")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.primaryDark.opacity(0.5))
                }
            }
            
            Spacer()
            
            if isMember {
                HStack(spacing: 4) {
                    Text("View")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Color("DeepSpace"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color("DeepSpace").opacity(0.1))
                .cornerRadius(10)
            } else {
                if isJoining {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color("DeepSpace")))
                        .scaleEffect(0.8)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Join")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color("DeepSpace"))
                    .cornerRadius(10)
                }
            }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("DeepSpace").opacity(0.1),
                                        Color("DeepSpace").opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(Color("DeepSpace").opacity(0.1))
                .frame(width: 70, height: 70)
                .cornerRadius(12)
            
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(Color("DeepSpace").opacity(0.4))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color("DeepSpace").opacity(0.1), lineWidth: 1)
        )
    }
}
