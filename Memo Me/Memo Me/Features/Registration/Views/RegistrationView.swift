//
//  RegistrationView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import PhotosUI

@MainActor
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
                let preferNotToSay = "Prefer not to say"
                let notInList = "Not yet in the list"
                let notInListValue = "Not yet in the list"
                let countryPlaceholder = "Select your country"
                
                if newValue == preferNotToSay {
                    viewModel.country = nil
                    viewModel.countryConfig.text = countryPlaceholder
                    return
                }
                
                if newValue == countryPlaceholder && oldValue != countryPlaceholder {
                    if viewModel.country != nil {
                        viewModel.country = nil
                    }
                    return
                }
                
                if newValue == notInList {
                    viewModel.selectCountry(notInListValue)
                    return
                }
                
                if newValue != countryPlaceholder && 
                   newValue != oldValue && 
                   newValue != preferNotToSay &&
                   newValue != notInList &&
                   viewModel.country != newValue {
                    viewModel.selectCountry(newValue)
                }
            }
        }
        .onChange(of: viewModel.primaryExpertiseConfig.text) { oldValue, newValue in
            Task { @MainActor in
                let preferNotToSay = "Prefer not to say"
                let notInList = "Not yet in the list"
                let notInListValue = "Not yet in the list"
                let interestsPlaceholder = "Select your professional interests"
                
                if newValue == preferNotToSay || (newValue == interestsPlaceholder && oldValue != interestsPlaceholder && viewModel.primaryExpertiseArea != nil) {
                    viewModel.clearPrimaryExpertise()
                } else if newValue == notInList {
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
                let preferNotToSay = "Prefer not to say"
                let notInList = "Not yet in the list"
                let notInListValue = "Not yet in the list"
                let interestsPlaceholder = "Select your professional interests"
                
                if newValue == preferNotToSay || (newValue == interestsPlaceholder && oldValue != interestsPlaceholder && viewModel.secondaryExpertiseArea != nil) {
                    viewModel.clearSecondaryExpertise()
                } else if newValue == notInList {
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
    
    private var titleSection: some View {
        Text(buildTitleText())
            .foregroundColor(.primaryDark)
            .multilineTextAlignment(.center)
            .padding(.top, 20)
            .padding(.horizontal, 20)
    }
    
    private var profilePhotoSection: some View {
        let profileImage = viewModel.profileImage
        let isLoading = viewModel.isLoading
        
        return VStack(spacing: 16) {
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
                        if let image = profileImage {
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
                            Image(systemName: profileImage != nil ? "arrow.2.circlepath" : "camera.fill")
                                .font(.system(size: profileImage != nil ? 14 : 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 50, y: 50)
                }
                .frame(height: 180)
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 20)
    }
    
    private var nameFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preferred name *")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primaryDark)
            
            TextField("e.g. John Smith", text: $viewModel.name)
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
            Text("Focus Area")
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
                        Text("Understood")
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
        let isLoading = viewModel.isLoading
        let isFormValid = viewModel.isFormValid
        
        return Button(action: {
            Task {
                _ = await viewModel.submitRegistration()
            }
        }) {
            HStack {
                if isLoading {
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
                isFormValid && !isLoading
                ? Color(.deepSpace)
                : Color.gray.opacity(0.5)
            )
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isLoading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 40)
    }
    
    private func buildTitleText() -> AttributedString {
        let baseText = "Add your details to personalize your experience"
        let keyword = "personalize"
        var attributedString = AttributedString(baseText)
        attributedString.font = .system(size: 20, weight: .medium, design: .rounded)
        if let range = attributedString.range(of: keyword) {
            attributedString[range].font = .system(size: 24, weight: .bold, design: .rounded)
        }
        
        return attributedString
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
