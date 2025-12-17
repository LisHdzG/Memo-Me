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
    @State private var showDiscardChangesAlert: Bool = false
    
    enum Field {
        case name
        case instagram
        case linkedin
    }
    
    @MainActor var body: some View {
        ZStack {
            Color(.ghostWhite)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        let profileImage = viewModel.profileImage
                        let isLoading = viewModel.isLoading
                        let photoUrl = authManager.currentUser?.photoUrl
                        
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
                                    } else if let photoUrl {
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
                                        Image(systemName: (profileImage != nil || photoUrl != nil) ? "arrow.2.circlepath" : "camera.fill")
                                            .font(.system(size: (profileImage != nil || photoUrl != nil) ? 14 : 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 50, y: 50)
                            }
                            .frame(height: 180)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(buildNameLabel())
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextField("e.g. John Smith", text: $viewModel.name)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Country (optional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryDark)
                        
                        Button {
                            focusedField = nil
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primaryDark.opacity(0.7))
                            Text("Instagram (optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primaryDark)
                        }
                        
                        HStack(spacing: 8) {
                            Text("@")
                                .font(.system(size: 16))
                                .foregroundColor(.primaryDark.opacity(0.6))
                                .padding(.leading, 4)
                            
                            TextField("your_username", text: $viewModel.instagramUrl)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($focusedField, equals: .instagram)
                                .keyboardType(.default)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                        }
                        
                        Text("Enter only your username (without @ or URL)")
                            .font(.system(size: 12))
                            .foregroundColor(.primaryDark.opacity(0.5))
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "briefcase.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primaryDark.opacity(0.7))
                            Text("LinkedIn (optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primaryDark)
                        }
                        
                        TextField("your_profile", text: $viewModel.linkedinUrl)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($focusedField, equals: .linkedin)
                            .keyboardType(.default)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                        
                        Text("Enter only your profile name (without URL)")
                            .font(.system(size: 12))
                            .foregroundColor(.primaryDark.opacity(0.5))
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 20)
                    
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interests (optional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryDark)
                        
                        Button {
                            focusedField = nil
                            viewModel.showInterestsSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color("RoyalPurple"))
                                
                                Text("Add interests")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primaryDark)
                                
                                Spacer()
                                
                                if !viewModel.selectedInterests.isEmpty {
                                    Text("\(viewModel.selectedInterests.count)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color("RoyalPurple"))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        
                        if !viewModel.selectedInterests.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(viewModel.selectedInterests, id: \.self) { interest in
                                    HStack(spacing: 6) {
                                        Text(interest)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primaryDark)
                                        
                                        Button(action: {
                                            viewModel.removeInterest(interest)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(.electricRuby))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(16)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    
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
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Profile")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color("DeepSpace"))
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if viewModel.isDataLoaded && viewModel.hasChanges {
                        showDiscardChangesAlert = true
                    } else {
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                    }
                    .font(.system(size: 17))
                    .foregroundColor(Color("RoyalPurple"))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isDataLoaded && viewModel.hasChanges {
                    Button(action: {
                        Task { @MainActor in
                            let success = await viewModel.saveProfile()
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        Text("Save")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color("RoyalPurple"))
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        if viewModel.isDataLoaded && viewModel.hasChanges {
                            showDiscardChangesAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
        )
        .interactiveDismissDisabled(viewModel.isDataLoaded && viewModel.hasChanges)
        .confirmationDialog(
            "Discard Changes?",
            isPresented: $showDiscardChangesAlert,
            titleVisibility: .visible
        ) {
            Button("Save", role: .none) {
                Task { @MainActor in
                    let success = await viewModel.saveProfile()
                    if success {
                        dismiss()
                    }
                }
            }
            
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            
            Button("Continue Editing", role: .cancel) { }
        } message: {
            Text("If you go back, your changes will be lost.")
        }
        .onAppear {
            viewModel.authenticationManager = authManager
            viewModel.loadUserData()
        }
        .customPicker($viewModel.countryConfig, items: viewModel.countries, addNotInList: true, notInListText: viewModel.notInListCountry)
        .customPicker($viewModel.primaryExpertiseConfig, items: viewModel.expertiseAreas, addNotInList: true)
        .customPicker($viewModel.secondaryExpertiseConfig, items: viewModel.expertiseAreas, addNotInList: true)
        .sheet(isPresented: $viewModel.showInterestsSheet) {
            InterestSelectionSheet(viewModel: viewModel)
        }
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
        .overlay {
            if viewModel.isLoading {
                LoaderView()
            }
        }
    }
    
    private var userName: String {
        authManager.currentUser?.name ?? authManager.userName ?? "User"
    }
    
    private var primaryAreaView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Primary area")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primaryDark.opacity(0.7))
            
            Button {
                focusedField = nil
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
                focusedField = nil
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
    
    private func buildNameLabel() -> AttributedString {
        var attributedString = AttributedString("Name ")
        attributedString.foregroundColor = .primaryDark
        
        var asterisk = AttributedString("*")
        asterisk.foregroundColor = Color("RoyalPurple")
        attributedString.append(asterisk)
        
        return attributedString
    }
}
