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
                Color(.ghostWhite)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color("DeepSpace").opacity(0.7))
                                
                                Text("Foto del espacio (opcional)")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primaryDark)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
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
                                            .foregroundColor(Color("DeepSpace").opacity(0.4))
                                        
                                        Text("Agregar foto")
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
                            }
                        }
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre del espacio *")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.primaryDark)
                            
                            TextField("Ingresa el nombre del espacio", text: $viewModel.name)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
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
                            Text("Descripción")
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
                            HStack(spacing: 8) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color("DeepSpace").opacity(0.7))
                                
                                Text("Tipos de espacio")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primaryDark)
                            }
                            
                            Text("Selecciona uno o más tipos (opcional)")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.6))
                            
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
                                        .background(viewModel.selectedTypes.contains(type) ? Color("DeepSpace").opacity(0.15) : Color.white.opacity(0.3))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(viewModel.selectedTypes.contains(type) ? Color("DeepSpace").opacity(0.3) : Color("DeepSpace").opacity(0.1), lineWidth: 1.5)
                                        )
                                    }
                                }
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
                                    Text(viewModel.isPublic ? "Público" : "Privado")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primaryDark)
                                    
                                    Text(viewModel.isPublic ? "Cualquiera puede unirse" : "Solo con código")
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
                                    if let userId = authManager.currentUser?.id {
                                    if let createdSpace = await viewModel.createSpace(userId: userId) {
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
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color("DeepSpace").opacity(0.7))
                                .cornerRadius(12)
                            } else {
                                Text("Crear espacio")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color("DeepSpace"))
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
            .navigationTitle("Crear espacio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(Color("DeepSpace"))
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
}


