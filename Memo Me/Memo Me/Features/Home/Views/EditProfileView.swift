//
//  EditProfileView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name
        case instagram
        case linkedin
    }
    
    var body: some View {
        ZStack {
            Color(.ghostWhite)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header con botones
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                dismiss()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primaryDark)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                                .shadow(color: .primaryDark.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        Spacer()
                        
                        Text("Editar Perfil")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primaryDark)
                        
                        Spacer()
                        
                        if viewModel.hasChanges {
                            Button(action: {
                                Task {
                                    let success = await viewModel.saveProfile()
                                    if success {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            dismiss()
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.deepSpace))
                                    .clipShape(Circle())
                                    .shadow(color: .primaryDark.opacity(0.2), radius: 6, x: 0, y: 3)
                            }
                            .disabled(viewModel.isLoading)
                            .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isLoading)
                        } else {
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Foto de perfil
                    VStack(spacing: 16) {
                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            let profileImage = viewModel.profileImage
                            let isLoading = viewModel.isLoading
                            let hasPhotoUrl = authManager.currentUser?.photoUrl != nil
                            
                            ZStack {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                    .foregroundColor(.primaryDark)
                                    .frame(width: 140, height: 140)
                                
                                ZStack {
                                    if let image = profileImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 130, height: 130)
                                            .clipShape(Circle())
                                    } else if let photoUrl = authManager.currentUser?.photoUrl {
                                        AsyncImageView(
                                            imageUrl: photoUrl,
                                            placeholderText: userName,
                                            contentMode: .fill,
                                            size: 130
                                        )
                                        .clipShape(Circle())
                                    } else {
                                        VStack(spacing: 8) {
                                            Image("MemoMePhoto")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 60, height: 60)
                                            
                                            Text("Add photo")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primaryDark)
                                        }
                                    }
                                    
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryDark))
                                    }
                                }
                                .frame(width: 130, height: 130)
                                
                                Circle()
                                    .fill(.primaryDark)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: (profileImage != nil || hasPhotoUrl) ? "arrow.2.circlepath" : "camera.fill")
                                            .font(.system(size: (profileImage != nil || hasPhotoUrl) ? 14 : 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 50, y: 50)
                            }
                            .frame(height: 180)
                        }
                        .disabled(viewModel.isLoading)
                        
                        let hasPhotoUrl = authManager.currentUser?.photoUrl != nil
                        if viewModel.profileImage != nil || hasPhotoUrl {
                            Button(action: {
                                viewModel.removePhoto()
                            }) {
                                Text("Eliminar foto")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(.electricRuby))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Nombre
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Nombre")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primaryDark)
                            
                            Text("*")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(.electricRuby))
                        }
                        
                        TextField("e.g. John Smith", text: $viewModel.name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                    }
                    .padding(.horizontal, 20)
                    
                    // País
                    VStack(alignment: .leading, spacing: 8) {
                        Text("País (opcional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryDark)
                        
                        Button {
                            viewModel.countryConfig.show.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                                
                                Text(viewModel.countryConfig.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(viewModel.country == nil ? .primaryDark.opacity(0.6) : .primaryDark)
                                
                                Spacer()
                                
                                SourcePickerView(config: $viewModel.countryConfig)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if viewModel.country != nil {
                            Button(action: {
                                viewModel.clearCountry()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Limpiar selección")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(Color(.electricRuby))
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Instagram
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primaryDark.opacity(0.7))
                            Text("Instagram (opcional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primaryDark)
                        }
                        
                        HStack(spacing: 8) {
                            Text("@")
                                .font(.system(size: 16))
                                .foregroundColor(.primaryDark.opacity(0.6))
                                .padding(.leading, 4)
                            
                            TextField("tu_usuario", text: $viewModel.instagramUrl)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($focusedField, equals: .instagram)
                                .keyboardType(.default)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                        }
                        
                        Text("Solo ingresa tu nombre de usuario (sin @ ni URL)")
                            .font(.system(size: 12))
                            .foregroundColor(.primaryDark.opacity(0.5))
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // LinkedIn
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primaryDark.opacity(0.7))
                            Text("LinkedIn (opcional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primaryDark)
                        }
                        
                        TextField("tu_perfil", text: $viewModel.linkedinUrl)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($focusedField, equals: .linkedin)
                            .keyboardType(.default)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                        
                        Text("Solo ingresa tu nombre de perfil (sin URL)")
                            .font(.system(size: 12))
                            .foregroundColor(.primaryDark.opacity(0.5))
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // Áreas de expertise
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Áreas de expertise (opcional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryDark)
                        
                        Button {
                            viewModel.areasConfig.show.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                                
                                Text(viewModel.areasConfig.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                                
                                Spacer()
                                
                                SourcePickerView(config: $viewModel.areasConfig)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if !viewModel.selectedAreas.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.selectedAreas, id: \.self) { area in
                                    HStack {
                                        Text(area)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primaryDark)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.removeArea(area)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(Color(.electricRuby))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Intereses
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intereses (opcional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryDark)
                        
                        Button {
                            viewModel.interestsConfig.show.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                                
                                Text(viewModel.interestsConfig.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                                
                                Spacer()
                                
                                SourcePickerView(config: $viewModel.interestsConfig)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if !viewModel.selectedInterests.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(viewModel.selectedInterests, id: \.self) { interest in
                                    HStack {
                                        Text(interest)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primaryDark)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            viewModel.removeInterest(interest)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(Color(.electricRuby))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Mensajes de error/éxito
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(.electricRuby))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    
                    if let successMessage = viewModel.successMessage {
                        Text(successMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryDark)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            viewModel.authenticationManager = authManager
            viewModel.loadUserData()
        }
        .customPicker($viewModel.countryConfig, items: viewModel.countries)
        .customPicker($viewModel.areasConfig, items: viewModel.expertiseAreas)
        .customPicker($viewModel.interestsConfig, items: viewModel.interestsOptions)
        .onChange(of: viewModel.countryConfig.text) { oldValue, newValue in
            Task { @MainActor in
                let countryPlaceholder = "Select your country"
                if newValue != countryPlaceholder &&
                   newValue != oldValue &&
                   viewModel.country != newValue {
                    viewModel.selectCountry(newValue)
                }
            }
        }
        .onChange(of: viewModel.areasConfig.text) { oldValue, newValue in
            Task { @MainActor in
                let interestsPlaceholder = "Select your professional interests"
                if newValue != interestsPlaceholder &&
                   newValue != oldValue {
                    viewModel.addArea(newValue)
                }
            }
        }
        .onChange(of: viewModel.interestsConfig.text) { oldValue, newValue in
            Task { @MainActor in
                if newValue != "Seleccionar interés" &&
                   newValue != oldValue {
                    viewModel.addInterest(newValue)
                }
            }
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

