//
//  ContactDetailView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct ContactDetailView: View {
    let space: Space?
    
    @StateObject private var viewModel = ContactDetailViewModel()
    @State private var rotationSpeed: Double = 1.5
    @State private var isAutoRotating: Bool = true
    @State private var selectedContact: Contact?
    @State private var selectedUser: User?
    @State private var showContactDetail: Bool = false
    @State private var isLoadingUser: Bool = false
    @State private var showQRCode: Bool = false
    @State private var showLeaveSpaceAlert: Bool = false
    @State private var isLeavingSpace: Bool = false
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    @EnvironmentObject var authManager: AuthenticationManager
    
    init(space: Space? = nil) {
        self.space = space
    }
    
    var body: some View {
        ZStack {
            Color(.ghostWhite)
                .ignoresSafeArea()
            mainContent
        }
        .task {
            viewModel.currentUserId = authManager.currentUser?.id
            await viewModel.loadContacts(for: space ?? spaceSelectionService.selectedSpace)
        }
        .onChange(of: spaceSelectionService.selectedSpace) { oldValue, newValue in
            Task {
                await viewModel.loadContacts(for: newValue)
            }
        }
        .onChange(of: authManager.currentUser?.id) { oldValue, newValue in
            viewModel.currentUserId = newValue
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .onAppear {
            rotationSpeed = 1.5
            isAutoRotating = true
        }
        .overlay {
            if viewModel.isLoading && viewModel.contacts.isEmpty {
                LoaderView()
            }
        }
        .sheet(isPresented: $showQRCode) {
            if let spaceCode = (space ?? spaceSelectionService.selectedSpace)?.code {
                QRCodeSheetView(code: spaceCode)
            }
        }
        .alert("Leave Space", isPresented: $showLeaveSpaceAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await leaveSpace()
                }
            }
        } message: {
            Text("If you leave this space, no one will be able to view your profile in this context. You can always rejoin later.")
        }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if spaceSelectionService.selectedSpace != nil {
                    headerSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                errorMessageView
                contactsContent
            }
            
            if spaceSelectionService.selectedSpace != nil {
                VStack {
                    Spacer()
                    leaveSpaceButton
                        .padding(.bottom, 30)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: spaceSelectionService.selectedSpace?.spaceId)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                if spaceSelectionService.selectedSpace != nil {
                    Text(space?.name ?? spaceSelectionService.selectedSpace?.name ?? "My Contacts")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color("DeepSpace"))
                }
                
                Spacer()
                
                if spaceSelectionService.selectedSpace != nil {
                    changeSpaceButton
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(.ghostWhite))
    }
    
    private var changeSpaceButton: some View {
        NavigationLink(destination: SpacesListView(shouldDismissOnSelection: true)) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 14, weight: .medium))
                Text("Spaces")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(Color("DeepSpace"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("DeepSpace").opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .background(Color(.electricRuby).opacity(0.9))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .shadow(color: Color(.electricRuby).opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private var contactsContent: some View {
        if spaceSelectionService.selectedSpace == nil {
            noSpaceSelectedView
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else if !viewModel.contacts.isEmpty {
            ZStack {
                Color(.ghostWhite)
                    .ignoresSafeArea()
                
                ContactSphereView(
                    contacts: viewModel.contacts,
                    rotationSpeed: $rotationSpeed,
                    isAutoRotating: $isAutoRotating,
                    onContactTapped: { contact in
                        selectedContact = contact
                        selectedUser = viewModel.getUser(for: contact)
                        
                        if selectedUser == nil, let userId = contact.userId {
                            isLoadingUser = true
                            Task {
                                do {
                                    let userService = UserService()
                                    let loadedUser = try await userService.getUser(userId: userId)
                                    await MainActor.run {
                                        selectedUser = loadedUser
                                        isLoadingUser = false
                                        showContactDetail = true
                                    }
                                } catch {
                                    await MainActor.run {
                                        isLoadingUser = false
                                        showContactDetail = true
                                    }
                                }
                            }
                        } else {
                            showContactDetail = true
                        }
                    }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .navigationDestination(isPresented: $showContactDetail) {
                if let contact = selectedContact {
                    ContactDetailPageView(
                        user: selectedUser,
                        contact: contact,
                        spaceId: space?.spaceId ?? spaceSelectionService.selectedSpace?.spaceId
                    )
                } else {
                    EmptyView()
                }
            }
            .onChange(of: showContactDetail) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedContact = nil
                        selectedUser = nil
                        isLoadingUser = false
                    }
                }
            }
        } else {
            emptyContactsView
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
    
    private var noSpaceSelectedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Are you lost?")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color("DeepSpace"))
            
            Image("MemoMeScared")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            
            Text("You have not selected a space")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color("DeepSpace"))
            
            Text("To view members and connect with them, you need to join a context.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, -10)
            
            NavigationLink(destination: SpacesListView(shouldDismissOnSelection: true)) {
                Text("Go to spaces")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color("DeepSpace"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.ghostWhite))
    }
    
    private var emptyContactsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.primaryDark.opacity(0.3))
            
            VStack(spacing: 12) {
                Text("No members yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color("DeepSpace"))
                
                Text("Only you are here. Share the QR code of this space and let others join!")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let spaceCode = (space ?? spaceSelectionService.selectedSpace)?.code {
                Button(action: {
                    showQRCode = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Show QR Code")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("DeepSpace"),
                                Color("DeepSpace").opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color("DeepSpace").opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.ghostWhite))
    }
    
    private var leaveSpaceButton: some View {
        Button(action: {
            showLeaveSpaceAlert = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .medium))
                Text("Leave Space")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
            }
            .foregroundColor(.primaryDark.opacity(0.6))
        }
        .disabled(isLeavingSpace)
    }
    
    private func leaveSpace() async {
        guard let currentSpace = space ?? spaceSelectionService.selectedSpace,
              let userId = authManager.currentUser?.id else {
            return
        }
        
        isLeavingSpace = true
        
        do {
            let spaceService = SpaceService()
            try await spaceService.leaveSpace(spaceId: currentSpace.spaceId, userId: userId)
            
            spaceSelectionService.clearSelectedSpace()
            ContactCacheService.shared.clearCache(for: currentSpace.spaceId)
            viewModel.stopListening()
            
            isLeavingSpace = false
        } catch {
            isLeavingSpace = false
            viewModel.errorMessage = "Error leaving space: \(error.localizedDescription)"
        }
    }
}
