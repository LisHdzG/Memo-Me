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
    @State private var isEditing: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Text("Mi Perfil")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Botón de editar
                            if !isEditing {
                                Button(action: {
                                    startEditing()
                                }) {
                                    Text("Editar")
                                        .font(.system(size: 16, weight: .semibold))
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
                            
                            // Botones cuando está en edición
                            if isEditing {
                                HStack(spacing: 12) {
                                    // Botón Cancelar
                                    Button(action: {
                                        cancelEditing()
                                    }) {
                                        Text("Cancelar")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.white.opacity(0.2),
                                                        Color.white.opacity(0.1)
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
                                    
                                    // Botón de guardar (solo si hay cambios)
                                    if viewModel.hasChanges {
                                        Button(action: {
                                            Task {
                                                let success = await viewModel.saveProfile()
                                                if success {
                                                    isEditing = false
                                                }
                                            }
                                        }) {
                                            Text("Guardar")
                                                .font(.system(size: 16, weight: .semibold))
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
                                        .disabled(viewModel.isLoading)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Photo Section
                    if isEditing {
                        VStack(spacing: 12) {
                            Text("Foto de perfil (opcional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            PhotosPicker(
                                selection: $viewModel.selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                ZStack {
                                    if let image = viewModel.profileImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    } else if let photoUrl = authManager.currentUser?.photoUrl, let url = URL(string: photoUrl) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                        }
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 120, height: 120)
                                        
                                        Text(String(userName.prefix(1)))
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                }
                            }
                            .disabled(viewModel.isLoading)
                            
                            if viewModel.profileImage != nil || authManager.currentUser?.photoUrl != nil {
                                Button(action: {
                                    viewModel.removePhoto()
                                }) {
                                    Text("Eliminar foto")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // Vista de solo lectura de foto
                        VStack(spacing: 16) {
                            if let photoUrl = authManager.currentUser?.photoUrl, let url = URL(string: photoUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                )
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                    
                                    Text(String(userName.prefix(1)))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                )
                            }
                            
                            Text(userName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 10)
                    }
                    
                    // Name Section
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Nombre")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("*")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            
                            TextField("Ingresa tu nombre", text: $viewModel.name)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($focusedField, equals: .name)
                                .submitLabel(.next)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Nationality Section
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nacionalidad (opcional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Button {
                                viewModel.nationalityConfig.show.toggle()
                            } label: {
                                HStack {
                                    Text(viewModel.nationalityConfig.text)
                                        .font(.system(size: 16))
                                        .foregroundColor(viewModel.nationality == nil ? Color.white.opacity(0.6) : Color.white)
                                    
                                    Spacer()
                                    
                                    SourcePickerView(config: $viewModel.nationalityConfig)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                            
                            if viewModel.nationality != nil {
                                Button(action: {
                                    viewModel.clearNationality()
                                }) {
                                    HStack {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Limpiar selección")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.red.opacity(0.8))
                                }
                                .padding(.leading, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ProfileInfoSection(
                            title: "Nacionalidad",
                            displayValue: authManager.currentUser?.nationality ?? "No especificada"
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Areas Section
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Áreas de expertise (opcional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Button {
                                viewModel.areasConfig.show.toggle()
                            } label: {
                                HStack {
                                    Text(viewModel.areasConfig.text)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.white.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    SourcePickerView(config: $viewModel.areasConfig)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                            
                            // Mostrar áreas seleccionadas
                            if !viewModel.selectedAreas.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.selectedAreas, id: \.self) { area in
                                        HStack {
                                            Text(area)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                viewModel.removeArea(area)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.red.opacity(0.8))
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ProfileInfoSection(
                            title: "Áreas",
                            displayValue: areasDisplay
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Interests Section
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Intereses (opcional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Button {
                                viewModel.interestsConfig.show.toggle()
                            } label: {
                                HStack {
                                    Text(viewModel.interestsConfig.text)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.white.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    SourcePickerView(config: $viewModel.interestsConfig)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                            
                            // Mostrar intereses seleccionados
                            if !viewModel.selectedInterests.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(viewModel.selectedInterests, id: \.self) { interest in
                                        HStack {
                                            Text(interest)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                viewModel.removeInterest(interest)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.red.opacity(0.8))
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        ProfileInfoSection(
                            title: "Intereses",
                            displayValue: interestsDisplay
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Error/Success Messages
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    
                    if let successMessage = viewModel.successMessage {
                        Text(successMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    
                    // Botones de acción (solo cuando no está en edición)
                    if !isEditing {
                        VStack(spacing: 16) {
                            // Botón de cerrar sesión
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
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.orange.opacity(0.6),
                                            Color.orange.opacity(0.4)
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
                            
                            // Botón de eliminar cuenta
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
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.red.opacity(0.6),
                                            Color.red.opacity(0.4)
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
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 50)
                    } else {
                        // Espaciado cuando está en edición
                        Spacer()
                            .frame(height: 50)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            viewModel.authenticationManager = authManager
            if !isEditing {
                viewModel.loadUserData()
            }
        }
        .customPicker($viewModel.nationalityConfig, items: viewModel.nationalities)
        .customPicker($viewModel.areasConfig, items: viewModel.expertiseAreas)
        .customPicker($viewModel.interestsConfig, items: viewModel.interestsOptions)
        .onChange(of: viewModel.nationalityConfig.text) { oldValue, newValue in
            if newValue != "Seleccionar nacionalidad" &&
               newValue != oldValue &&
               viewModel.nationality != newValue {
                viewModel.selectNationality(newValue)
            }
        }
        .onChange(of: viewModel.areasConfig.text) { oldValue, newValue in
            if newValue != "Seleccionar área" &&
               newValue != oldValue {
                viewModel.addArea(newValue)
            }
        }
        .onChange(of: viewModel.interestsConfig.text) { oldValue, newValue in
            if newValue != "Seleccionar interés" &&
               newValue != oldValue {
                viewModel.addInterest(newValue)
            }
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
    }
    
    private var userName: String {
        authManager.currentUser?.name ?? authManager.userName ?? "Usuario"
    }
    
    private var areasDisplay: String {
        guard let areas = authManager.currentUser?.areas, !areas.isEmpty else {
            return "No especificadas"
        }
        return areas.joined(separator: ", ")
    }
    
    private var interestsDisplay: String {
        guard let interests = authManager.currentUser?.interests, !interests.isEmpty else {
            return "No especificados"
        }
        return interests.joined(separator: ", ")
    }
    
    private func startEditing() {
        viewModel.loadUserData()
        isEditing = true
    }
    
    private func cancelEditing() {
        // Recargar los datos originales
        viewModel.loadUserData()
        isEditing = false
    }
}

// Componente para mostrar secciones de información
struct ProfileInfoSection: View {
    let title: String
    let displayValue: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(displayValue)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}
