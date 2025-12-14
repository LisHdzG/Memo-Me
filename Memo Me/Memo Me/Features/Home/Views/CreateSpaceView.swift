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
    
    var body: some View {
        NavigationView {
            ZStack {
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
                        // Banner Image Section
                        VStack(spacing: 16) {
                            Text("Foto del espacio (opcional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
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
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .padding(8)
                                }
                            } else {
                                PhotosPicker(
                                    selection: $viewModel.selectedPhotoItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Text("Agregar foto")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .frame(width: 200, height: 200)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre del espacio *")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextField("Ingresa el nombre del espacio", text: $viewModel.name)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(16)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .autocapitalization(.words)
                                .onChange(of: viewModel.name) { oldValue, newValue in
                                    viewModel.validateName()
                                }
                            
                            if let nameError = viewModel.nameError {
                                Text(nameError)
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.9))
                                    .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Description Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descripción")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
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
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text("\(viewModel.description.count) / 500")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Space Types Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tipos de espacio")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Selecciona uno o más tipos (opcional)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            
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
                                                .foregroundColor(viewModel.selectedTypes.contains(type) ? Color("PurpleGradientTop") : .white.opacity(0.6))
                                            
                                            Text(type)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(viewModel.selectedTypes.contains(type) ? Color("PurpleGradientTop").opacity(0.3) : Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(viewModel.selectedTypes.contains(type) ? Color("PurpleGradientTop") : Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Public/Private Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Visibilidad")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.isPublic ? "Público" : "Privado")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(viewModel.isPublic ? "Cualquiera puede unirse" : "Solo con código")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $viewModel.isPublic)
                                    .toggleStyle(SwitchToggleStyle(tint: Color("PurpleGradientTop")))
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Create Button
                        Button(action: {
                            Task {
                                if let userId = authManager.currentUser?.id {
                                    if let createdSpace = await viewModel.createSpace(userId: userId) {
                                        // Seleccionar el espacio creado
                                        spaceSelectionService.saveSelectedSpace(createdSpace)
                                        dismiss()
                                    }
                                }
                            }
                        }) {
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Creando...")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color("PurpleGradientTop").opacity(0.7))
                                .cornerRadius(12)
                            } else {
                                Text("Crear espacio")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color("PurpleGradientTop"))
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(viewModel.isLoading || viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 50)
                    }
                }
            }
            .navigationTitle("Crear espacio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}
