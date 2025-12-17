//
//  CreateSpaceView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI
import PhotosUI

struct CreateSpaceView: View {
    @StateObject private var viewModel = CreateSpaceViewModel()
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    @State private var showTypes = true
    @State private var showDismissAlert = false
    
    private func hasUnsavedChanges() -> Bool {
        let hasName = !viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDescription = !viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasPhoto = viewModel.bannerImage != nil
        let hasTypes = !viewModel.selectedTypes.isEmpty
        let visibilityChanged = viewModel.isPublic == false
        return hasName || hasDescription || hasPhoto || hasTypes || visibilityChanged
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color("DeepSpace").opacity(0.08),
                        Color("RoyalPurple").opacity(0.06),
                        Color(.ghostWhite)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color("DeepSpace").opacity(0.7))
                                    .padding(.leading, 4)
                                
                                Text("Space photo (optional)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primaryDark)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            
                            if let bannerImage = viewModel.bannerImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: bannerImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(16)
                                        .clipped()
                                    
                                    Button(action: {
                                        viewModel.removePhoto()
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(10)
                                            .background(
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color("DeepSpace"), Color("RoyalPurple").opacity(0.9)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            )
                                            .shadow(color: Color("DeepSpace").opacity(0.25), radius: 6, x: 0, y: 4)
                                    }
                                    .padding(10)
                                }
                                .padding(.horizontal, 16)
                            } else {
                                PhotosPicker(
                                    selection: $viewModel.selectedPhotoItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color("DeepSpace").opacity(0.4))
                                        
                                        Text("Add photo")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.primaryDark.opacity(0.6))
                                    }
                                    .frame(width: 200, height: 200)
                                    .background(Color("DeepSpace").opacity(0.05))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color("DeepSpace").opacity(0.15), lineWidth: 2)
                                    )
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Space name *")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primaryDark)
                            
                            TextField("Enter the space name", text: $viewModel.name)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.28))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color("DeepSpace").opacity(0.12), lineWidth: 1.2)
                                        )
                                )
                                .foregroundColor(.primaryDark)
                                .font(.system(size: 16, design: .rounded))
                                .autocapitalization(.words)
                                .onChange(of: viewModel.name) { oldValue, newValue in
                                    viewModel.validateName()
                                }
                            
                            if let nameError = viewModel.nameError {
                                Text(nameError)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(Color(.electricRuby))
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primaryDark)
                            
                            TextEditor(text: Binding(
                                get: { viewModel.description },
                                set: { newValue in
                                    if newValue.count <= 500 {
                                        viewModel.description = newValue
                                    }
                                }
                            ))
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.primaryDark)
                                .font(.system(size: 16, design: .rounded))
                                .scrollContentBackground(.hidden)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("DeepSpace").opacity(0.15), lineWidth: 1.5)
                                )
                            
                            Text("\(viewModel.description.count) / 500")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                    showTypes.toggle()
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color("DeepSpace"), Color("RoyalPurple").opacity(0.85)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 38, height: 38)
                                            .shadow(color: Color("DeepSpace").opacity(0.18), radius: 6, x: 0, y: 3)
                                        
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .rotationEffect(.degrees(showTypes ? 0 : -6))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Space types")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primaryDark)
                                        
                                        Text("Pick one or more vibes (optional)")
                                            .font(.system(size: 13, design: .rounded))
                                            .foregroundColor(.primaryDark.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.9))
                                            .frame(width: 32, height: 32)
                                            .shadow(color: Color("DeepSpace").opacity(0.08), radius: 4, x: 0, y: 2)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color("DeepSpace"))
                                            .rotationEffect(.degrees(showTypes ? 0 : -90))
                                            .animation(.easeInOut(duration: 0.2), value: showTypes)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color("DeepSpace").opacity(0.16),
                                                            Color("RoyalPurple").opacity(0.1)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.4
                                                )
                                        )
                                )
                                .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 3)
                            }
                            
                            if showTypes {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(viewModel.availableTypes, id: \.self) { type in
                                        Button(action: {
                                            if viewModel.selectedTypes.contains(type) {
                                                viewModel.selectedTypes.remove(type)
                                            } else {
                                                viewModel.selectedTypes.insert(type)
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: viewModel.selectedTypes.contains(type) ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(viewModel.selectedTypes.contains(type) ? Color("DeepSpace") : .primaryDark.opacity(0.4))
                                                
                                                Text(type)
                                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                                    .foregroundColor(.primaryDark)
                                                
                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(viewModel.selectedTypes.contains(type) ? Color("DeepSpace").opacity(0.16) : Color.white.opacity(0.34))
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(viewModel.selectedTypes.contains(type) ? Color("DeepSpace").opacity(0.3) : Color("DeepSpace").opacity(0.1), lineWidth: 1.2)
                                            )
                                        }
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color("DeepSpace").opacity(0.7))
                                
                                Text("Visibilidad")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primaryDark)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.isPublic ? "Public" : "Private")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primaryDark)
                                    
                                    Text(viewModel.isPublic ? "Anyone can join" : "Only with code")
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.primaryDark.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $viewModel.isPublic)
                                    .toggleStyle(SwitchToggleStyle(tint: Color("DeepSpace")))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("DeepSpace").opacity(0.1), lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Button(action: {
                            Task {
                                guard let userId = authManager.currentUser?.id else { return }
                                await LoaderPresenter.shared.show()
                                defer { Task { @MainActor in LoaderPresenter.shared.hide() } }
                                
                                if let createdSpace = await viewModel.createSpace(userId: userId) {
                                    spaceSelectionService.saveSelectedSpace(createdSpace)
                                    dismiss()
                                }
                            }
                        }) {
                            Text(viewModel.isLoading ? "Creating..." : "Create space")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color("DeepSpace"))
                                .cornerRadius(12)
                                .opacity(viewModel.isLoading ? 0.8 : 1)
                        }
                        .disabled(viewModel.isLoading || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                LoaderView()
                
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(.electricRuby).opacity(0.9))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 50)
                            .shadow(color: Color(.electricRuby).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Create space")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color("DeepSpace"))
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasUnsavedChanges() {
                            showDismissAlert = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(Color("DeepSpace"))
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .alert("Discard changes?", isPresented: $showDismissAlert) {
                Button("Keep editing", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Your changes will not be saved.")
            }
        }
    }
}


