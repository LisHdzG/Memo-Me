//
//  ContactDetailView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct ContactDetailView: View {
    let space: Space?
    
    @State private var contacts: [Contact] = []
    @State private var rotationSpeed: Double = 0.5 // Velocidad de rotación (radianes por segundo)
    @State private var isAutoRotating: Bool = true
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    
    init(space: Space? = nil) {
        self.space = space
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
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // Título y botón de cambiar espacio
                    HStack {
                        Text(space?.name ?? "Mis Contactos")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Botón para cambiar de espacio
                        Button(action: {
                            spaceSelectionService.clearSelectedSpace()
                        }) {
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
                    .padding(.horizontal, 20)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("\(contacts.count) contactos")
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
                
                // Esfera de contactos
                if !contacts.isEmpty {
                    ContactSphereView(
                        contacts: contacts,
                        rotationSpeed: $rotationSpeed,
                        isAutoRotating: $isAutoRotating
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !isLoading {
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
                
                // Controles
                VStack(spacing: 16) {
                    // Control de velocidad
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
                    
                    // Botón de pausa/reanudar
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
        }
        .task {
            await loadContacts()
        }
    }
    
    /// Carga los contactos del espacio desde Firestore
    private func loadContacts() async {
        guard let space = space, !space.memberIds.isEmpty else {
            // Si no hay espacio o no hay miembros, usar dummys como fallback
            contacts = Contact.generateDummyContacts()
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Obtener los usuarios del espacio
            let userService = UserService()
            let users = try await userService.getUsers(userIds: space.memberIds)
            
            // Convertir usuarios a Contact
            contacts = users.map { user in
                // Usar la URL de la foto de perfil si está disponible
                // Si no hay photoUrl, usar una imagen dummy como fallback
                let imageIndex = abs(user.id?.hashValue ?? 0) % 37 + 1
                let imageNumber = String(format: "%02d", imageIndex)
                
                return Contact(
                    id: UUID(uuidString: user.id ?? UUID().uuidString) ?? UUID(),
                    name: user.name,
                    imageName: user.photoUrl == nil ? "dummy_profile_\(imageNumber)" : nil,
                    imageUrl: user.photoUrl
                )
            }
            
            // Si no hay usuarios, usar dummys como fallback
            if contacts.isEmpty {
                contacts = Contact.generateDummyContacts()
            }
            
            isLoading = false
            print("✅ Contactos cargados: \(contacts.count)")
        } catch {
            errorMessage = "Error al cargar contactos: \(error.localizedDescription)"
            print("❌ Error al cargar contactos: \(error.localizedDescription)")
            // En caso de error, usar dummys como fallback
            contacts = Contact.generateDummyContacts()
            isLoading = false
        }
    }
}

#Preview {
    ContactDetailView()
}

