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
    @State private var rotationSpeed: Double = 0.5
    @State private var isAutoRotating: Bool = true
    @State private var selectedContact: Contact?
    @State private var selectedUser: User?
    @State private var showContactDetail: Bool = false
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    @EnvironmentObject var authManager: AuthenticationManager
    
    init(space: Space? = nil) {
        self.space = space
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
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
    }
    
    private var backgroundGradient: some View {
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
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            errorMessageView
            contactsContent
            controlsSection
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                if spaceSelectionService.selectedSpace != nil {
                    Text(space?.name ?? spaceSelectionService.selectedSpace?.name ?? "Mis Contactos")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("Contactos")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if spaceSelectionService.selectedSpace != nil {
                    changeSpaceButton
                }
            }
            .padding(.horizontal, 20)
            
            if viewModel.isLoading && spaceSelectionService.selectedSpace != nil {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else if spaceSelectionService.selectedSpace != nil {
                Text("\(viewModel.contacts.count) contactos")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var changeSpaceButton: some View {
        NavigationLink(destination: SpacesListView(shouldDismissOnSelection: true)) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 14, weight: .semibold))
                Text("Cambiar espacio")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.8))
                .cornerRadius(10)
                .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var contactsContent: some View {
        if spaceSelectionService.selectedSpace == nil {
            noSpaceSelectedView
        } else if !viewModel.contacts.isEmpty {
            ContactSphereView(
                contacts: viewModel.contacts,
                rotationSpeed: $rotationSpeed,
                isAutoRotating: $isAutoRotating,
                onContactTapped: { contact in
                    print("📱 Contacto tocado: \(contact.name), userId: \(contact.userId ?? "nil")")
                    selectedContact = contact
                    selectedUser = viewModel.getUser(for: contact)
                    
                    if selectedUser == nil, let userId = contact.userId {
                        Task {
                            do {
                                let userService = UserService()
                                selectedUser = try await userService.getUser(userId: userId)
                                showContactDetail = true
                            } catch {
                                print("⚠️ Error al obtener usuario: \(error)")
                                showContactDetail = true
                            }
                        }
                    } else {
                        showContactDetail = true
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sheet(isPresented: $showContactDetail) {
                if let contact = selectedContact {
                    ContactDetailSheet(
                        user: selectedUser,
                        contact: contact,
                        spaceId: space?.spaceId ?? spaceSelectionService.selectedSpace?.spaceId
                    )
                }
            }
        } else if !viewModel.isLoading {
            emptyContactsView
        }
    }
    
    private var noSpaceSelectedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Sin espacio seleccionado")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Selecciona un espacio para ver los contactos")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: SpacesListView(shouldDismissOnSelection: true)) {
                Text("Unirme a un espacio")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyContactsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No hay miembros en este espacio")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            speedControl
            pauseResumeButton
        }
    }
    
    private var speedControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Velocidad")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(String(format: "%.1fx", rotationSpeed))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Slider(value: $rotationSpeed, in: 0.1...2.0)
                .tint(.white)
        }
        .padding(.horizontal, 24)
    }
    
    private var pauseResumeButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAutoRotating.toggle()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: isAutoRotating ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 20))
                Text(isAutoRotating ? "Pausar" : "Reanudar")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }
}
