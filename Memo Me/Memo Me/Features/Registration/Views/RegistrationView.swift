//
//  RegistrationView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import PhotosUI

struct RegistrationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = RegistrationViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name
    }
    
    var body: some View {
        ZStack {
            Color(.ghostWhite)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text(buildTitleText())
                        .foregroundColor(.primaryDark)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        ZStack {

                            Circle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .foregroundColor(.primaryDark)
                                .frame(width: 140, height: 140)
                            
                            ZStack {
                                if let image = viewModel.profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 130, height: 130)
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
                                
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryDark))
                                }
                            }
                            .frame(width: 130, height: 130)
                            
                            PhotoPickerButton(
                                hasProfileImage: viewModel.profileImage != nil,
                                selection: $viewModel.selectedPhotoItem
                            )
                            .disabled(viewModel.isLoading)
                        }
                        .frame(height: 180)
                        
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred name *")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryDark)
                        
                        TextField("", text: $viewModel.name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($focusedField, equals: .name)
                            .onChange(of: viewModel.name) { oldValue, newValue in
                                Task { @MainActor in
                                    viewModel.validateName()
                                }
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nationality")
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
                                .foregroundColor(.red.opacity(0.8))
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Área principal de expertise
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focus Area")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryDark)
                        
                        Text("Primary area")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryDark.opacity(0.7))
                        
                        Button {
                            viewModel.primaryExpertiseConfig.show.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                                
                                Text(viewModel.primaryExpertiseConfig.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(viewModel.primaryExpertiseArea == nil ? .primaryDark.opacity(0.6) : .primaryDark)
                                
                                Spacer()
                                
                                SourcePickerView(config: $viewModel.primaryExpertiseConfig)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if viewModel.primaryExpertiseArea != nil {
                            Button(action: {
                                viewModel.clearPrimaryExpertise()
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
                    
                    // Área secundaria de expertise
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Secondary area")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primaryDark.opacity(0.7))
                        
                        Button {
                            viewModel.secondaryExpertiseConfig.show.toggle()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                                
                                Text(viewModel.secondaryExpertiseConfig.text)
                                    .font(.system(size: 16))
                                    .foregroundColor(viewModel.secondaryExpertiseArea == nil ? .primaryDark.opacity(0.6) : .primaryDark)
                                
                                Spacer()
                                
                                SourcePickerView(config: $viewModel.secondaryExpertiseConfig)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.primaryExpertiseArea == nil)
                        .opacity(viewModel.primaryExpertiseArea == nil ? 0.6 : 1.0)
                        
                        if viewModel.secondaryExpertiseArea != nil {
                            Button(action: {
                                viewModel.clearSecondaryExpertise()
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
                    
                    Button(action: {
                        Task {
                            let success = await viewModel.submitRegistration()
                            if success {
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text("Continue")
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
        .onAppear {
            viewModel.authenticationManager = authManager
            let appleName = authManager.userName
            if let name = appleName, viewModel.name.isEmpty {
                viewModel.name = name
            }
        }
        .customPicker($viewModel.countryConfig, items: viewModel.countries)
        .customPicker($viewModel.primaryExpertiseConfig, items: viewModel.expertiseAreas)
        .customPicker($viewModel.secondaryExpertiseConfig, items: viewModel.expertiseAreas)
        .onChange(of: viewModel.countryConfig.text) { oldValue, newValue in
            Task { @MainActor in
                if newValue != "Select your country" && 
                   newValue != oldValue && 
                   viewModel.country != newValue {
                    viewModel.selectCountry(newValue)
                }
            }
        }
        .onChange(of: viewModel.primaryExpertiseConfig.text) { oldValue, newValue in
            Task { @MainActor in
                if newValue != "Select your professional interests" && 
                   newValue != oldValue && 
                   viewModel.primaryExpertiseArea != newValue {
                    viewModel.selectPrimaryExpertise(newValue)
                }
            }
        }
        .onChange(of: viewModel.secondaryExpertiseConfig.text) { oldValue, newValue in
            Task { @MainActor in
                if newValue != "Select your professional interests" && 
                   newValue != oldValue && 
                   viewModel.secondaryExpertiseArea != newValue {
                    viewModel.selectSecondaryExpertise(newValue)
                }
            }
        }
        .errorSheets()
        .overlay {
            LoaderView()
        }
    }
    
    private func buildTitleText() -> AttributedString {
        var attributedString = AttributedString("Add your details to personalize your experience")
        attributedString.font = .system(size: 20, weight: .medium, design: .rounded)
        if let range = attributedString.range(of: "personalize") {
            attributedString[range].font = .system(size: 24, weight: .bold, design: .rounded)
        }
        
        return attributedString
    }
}

private struct PhotoPickerButton: View {
    let hasProfileImage: Bool
    @Binding var selection: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(
            selection: $selection,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Circle()
                .fill(.primaryDark)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: hasProfileImage ? "arrow.2.circlepath" : "camera.fill")
                        .font(.system(size: hasProfileImage ? 14 : 16, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
        .offset(x: 50, y: 50)
    }
}

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
