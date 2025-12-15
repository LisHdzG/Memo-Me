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
                    titleSection
                    profilePhotoSection
                    nameFieldSection
                    nationalitySection
                    focusAreaSection
                    errorMessageSection
                    continueButton
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    focusedField = nil
                }
        )
        .onAppear {
            viewModel.authenticationManager = authManager
            let appleName = authManager.userName
            if let name = appleName, viewModel.name.isEmpty {
                viewModel.name = name
            }
        }
        .customPicker($viewModel.countryConfig, items: viewModel.countries, addNotInList: true, notInListText: viewModel.notInListCountry)
        .customPicker($viewModel.primaryExpertiseConfig, items: viewModel.expertiseAreas, addNotInList: true)
        .customPicker($viewModel.secondaryExpertiseConfig, items: viewModel.expertiseAreas, addNotInList: true)
        .onChange(of: viewModel.countryConfig.text) { oldValue, newValue in
            Task { @MainActor in
                let preferNotToSay = String(localized: "picker.prefer.not.to.say", comment: "Prefer not to say option")
                let notInList = String(localized: "picker.not.in.list", comment: "Not in list option")
                let notInListValue = String(localized: "picker.not.in.list.value", comment: "Not yet in the list value")
                let countryPlaceholder = String(localized: "registration.select.country", comment: "Select country placeholder")
                
                // Si el nuevo valor es "Prefiero no decir" o si cambió al placeholder (después de seleccionar "Prefiero no decir")
                if newValue == preferNotToSay || (newValue == countryPlaceholder && oldValue != countryPlaceholder && viewModel.country != nil) {
                    // Si selecciona "Prefiero no decir", limpiar (nil)
                    viewModel.clearCountry()
                } else if newValue == notInList {
                    // Si selecciona "No está en la lista", guardar "Aún no está en la lista"
                    viewModel.selectCountry(notInListValue)
                } else if newValue != countryPlaceholder && 
                   newValue != oldValue && 
                   viewModel.country != newValue {
                    viewModel.selectCountry(newValue)
                }
            }
        }
        .onChange(of: viewModel.primaryExpertiseConfig.text) { oldValue, newValue in
            Task { @MainActor in
                let preferNotToSay = String(localized: "picker.prefer.not.to.say", comment: "Prefer not to say option")
                let notInList = String(localized: "picker.not.in.list", comment: "Not in list option")
                let notInListValue = String(localized: "picker.not.in.list.value", comment: "Not yet in the list value")
                let interestsPlaceholder = String(localized: "registration.select.interests", comment: "Select interests placeholder")
                
                // Si el nuevo valor es "Prefiero no decir" o si cambió al placeholder (después de seleccionar "Prefiero no decir")
                if newValue == preferNotToSay || (newValue == interestsPlaceholder && oldValue != interestsPlaceholder && viewModel.primaryExpertiseArea != nil) {
                    // Si selecciona "Prefiero no decir", limpiar (nil)
                    viewModel.clearPrimaryExpertise()
                } else if newValue == notInList {
                    // Si selecciona "No está en la lista", guardar "Aún no está en la lista"
                    viewModel.selectPrimaryExpertise(notInListValue)
                } else if newValue != interestsPlaceholder && 
                   newValue != oldValue && 
                   viewModel.primaryExpertiseArea != newValue {
                    viewModel.selectPrimaryExpertise(newValue)
                }
            }
        }
        .onChange(of: viewModel.secondaryExpertiseConfig.text) { oldValue, newValue in
            Task { @MainActor in
                let preferNotToSay = String(localized: "picker.prefer.not.to.say", comment: "Prefer not to say option")
                let notInList = String(localized: "picker.not.in.list", comment: "Not in list option")
                let notInListValue = String(localized: "picker.not.in.list.value", comment: "Not yet in the list value")
                let interestsPlaceholder = String(localized: "registration.select.interests", comment: "Select interests placeholder")
                
                // Si el nuevo valor es "Prefiero no decir" o si cambió al placeholder (después de seleccionar "Prefiero no decir")
                if newValue == preferNotToSay || (newValue == interestsPlaceholder && oldValue != interestsPlaceholder && viewModel.secondaryExpertiseArea != nil) {
                    // Si selecciona "Prefiero no decir", limpiar (nil)
                    viewModel.clearSecondaryExpertise()
                } else if newValue == notInList {
                    // Si selecciona "No está en la lista", guardar "Aún no está en la lista"
                    viewModel.selectSecondaryExpertise(notInListValue)
                } else if newValue != interestsPlaceholder && 
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
    
    // MARK: - View Components
    
    private var titleSection: some View {
        Text(buildTitleText())
            .foregroundColor(.primaryDark)
            .multilineTextAlignment(.center)
            .padding(.top, 20)
            .padding(.horizontal, 20)
    }
    
    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            PhotosPicker(
                selection: $viewModel.selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
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
                                
                                Text("registration.add.photo", comment: "Add photo text")
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
                    
                    Circle()
                        .fill(.primaryDark)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: viewModel.profileImage != nil ? "arrow.2.circlepath" : "camera.fill")
                                .font(.system(size: viewModel.profileImage != nil ? 14 : 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 50, y: 50)
                }
                .frame(height: 180)
            }
            .disabled(viewModel.isLoading)
        }
        .padding(.horizontal, 20)
    }
    
    private var nameFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("registration.preferred.name", comment: "Preferred name label")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryDark)
            
            TextField(String(localized: "registration.name.placeholder", comment: "Name placeholder example"), text: $viewModel.name)
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
                    .foregroundColor(Color(.electricRuby))
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var nationalitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("registration.nationality", comment: "Nationality label")
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
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primaryDark.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { newValue in
                    viewModel.countryConfig.sourceFrame = newValue
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var focusAreaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("registration.focus.area", comment: "Focus Area label")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryDark)
            
            VStack(spacing: 16) {
                primaryAreaView
                secondaryAreaView
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var primaryAreaView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("registration.primary.area", comment: "Primary area label")
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
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primaryDark.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { newValue in
                    viewModel.primaryExpertiseConfig.sourceFrame = newValue
                }
            }
        }
    }
    
    private var secondaryAreaView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("registration.secondary.area", comment: "Secondary area label")
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
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primaryDark.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .global)
                } action: { newValue in
                    viewModel.secondaryExpertiseConfig.sourceFrame = newValue
                }
            }
            .disabled(viewModel.primaryExpertiseArea == nil)
            .opacity(viewModel.primaryExpertiseArea == nil ? 0.6 : 1.0)
        }
    }
    
    private var errorMessageSection: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(.electricRuby))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        viewModel.clearError()
                    }) {
                        Text("registration.understood", comment: "Understood button")
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
        }
    }
    
    private var continueButton: some View {
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
                    Text("registration.continue", comment: "Continue button")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                viewModel.isFormValid && !viewModel.isLoading
                ? Color(.deepSpace)
                : Color.gray.opacity(0.5)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 40)
    }
    
    private func buildTitleText() -> AttributedString {
        let baseText = String(localized: "registration.title", comment: "Registration title")
        let keyword = String(localized: "registration.title.keyword", comment: "Keyword in title")
        var attributedString = AttributedString(baseText)
        attributedString.font = .system(size: 20, weight: .medium, design: .rounded)
        if let range = attributedString.range(of: keyword) {
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
            .tint(.deepSpace)
            .foregroundColor(.primaryDark)
            .font(.system(size: 16))
    }
}
