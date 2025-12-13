//
//  RegistrationView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import PhotosUI

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @FocusState private var focusedField: Field?
    @State private var showPhotoPermissionAlert = false
    
    enum Field {
        case name
    }
    
    var body: some View {
        ZStack {
            // Fondo con gradiente morado degradado
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
                    VStack(spacing: 16) {
                        Image("MemoMe")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                        
                        Text("Completa tu perfil")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color("SplashTextColor"))
                        
                        Text("Cuéntanos sobre ti")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("SplashTextColor").opacity(0.8))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Photo Section
                    VStack(spacing: 12) {
                        Text("Foto de perfil (opcional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("SplashTextColor").opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                if let image = viewModel.profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color("SplashTextColor").opacity(0.6))
                                }
                                
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        }
                        .disabled(viewModel.isLoading)
                        
                        if viewModel.profileImage != nil {
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
                    
                    // Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Nombre")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("SplashTextColor"))
                            
                            Text("*")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                        }
                        
                        TextField("Ingresa tu nombre", text: $viewModel.name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($focusedField, equals: .name)
                            .onChange(of: viewModel.name) { _, _ in
                                viewModel.validateName()
                            }
                            .submitLabel(.next)
                        
                        if let error = viewModel.nameError {
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Nationality Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nacionalidad (opcional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("SplashTextColor"))
                        
                        Button {
                            viewModel.nationalityConfig.show.toggle()
                        } label: {
                            HStack {
                                Text(viewModel.nationalityConfig.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(viewModel.nationality == nil ? Color("SplashTextColor").opacity(0.6) : Color("SplashTextColor"))
                                
                                Spacer()
                                
                                SourcePickerView(config: $viewModel.nationalityConfig)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color("SplashTextColor").opacity(0.6))
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
                    
                    // Expertise Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Área de expertise (opcional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("SplashTextColor"))
                        
                        Button {
                            viewModel.expertiseConfig.show.toggle()
                        } label: {
                            HStack {
                                Text(viewModel.expertiseConfig.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(viewModel.expertiseArea == nil ? Color("SplashTextColor").opacity(0.6) : Color("SplashTextColor"))
                                
                                Spacer()
                                
                                SourcePickerView(config: $viewModel.expertiseConfig)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color("SplashTextColor").opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if viewModel.expertiseArea != nil {
                            Button(action: {
                                viewModel.clearExpertise()
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
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                viewModel.clearError()
                            }) {
                                Text("Entendido")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Submit Button
                    Button(action: {
                        Task {
                            let success = await viewModel.submitRegistration()
                            if success {
                                // Aquí iría la navegación a la siguiente pantalla
                                print("Registro exitoso")
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("Continuar")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            viewModel.isFormValid && !viewModel.isLoading
                            ? Color.blue
                            : Color.gray.opacity(0.5)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .customPicker($viewModel.nationalityConfig, items: viewModel.nationalities)
        .customPicker($viewModel.expertiseConfig, items: viewModel.expertiseAreas)
        .onChange(of: viewModel.nationalityConfig.text) { oldValue, newValue in
            // Solo actualizar si el valor cambió y no es el placeholder
            if newValue != "Seleccionar nacionalidad" && 
               newValue != oldValue && 
               viewModel.nationality != newValue {
                viewModel.selectNationality(newValue)
            }
        }
        .onChange(of: viewModel.expertiseConfig.text) { oldValue, newValue in
            // Solo actualizar si el valor cambió y no es el placeholder
            if newValue != "Seleccionar área" && 
               newValue != oldValue && 
               viewModel.expertiseArea != newValue {
                viewModel.selectExpertise(newValue)
            }
        }
    }
}

// MARK: - Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(Color("SplashTextColor"))
            .font(.system(size: 16))
    }
}

#Preview {
    RegistrationView()
}
