//
//  ContactDetailView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct ContactDetailView: View {
    @State private var contacts: [Contact] = Contact.generateDummyContacts() // Cargar inmediatamente
    @State private var rotationSpeed: Double = 0.5 // Velocidad de rotación (radianes por segundo)
    @State private var isAutoRotating: Bool = true
    
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
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Mis Contactos")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(contacts.count) contactos")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Esfera de contactos
                ContactSphereView(
                    contacts: contacts,
                    rotationSpeed: $rotationSpeed,
                    isAutoRotating: $isAutoRotating
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Controles
                VStack(spacing: 16) {
                    // Control de velocidad
                    VStack(spacing: 8) {
                        HStack {
                            Text("Velocidad")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            Spacer()
                            Text(String(format: "%.1fx", rotationSpeed))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Slider(value: $rotationSpeed, in: 0.1...2.0)
                            .tint(.white)
                    }
                    .padding(.horizontal, 24)
                    
                    // Botón de pausa/reanudar
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAutoRotating.toggle()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isAutoRotating ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 20))
                            Text(isAutoRotating ? "Pausar" : "Reanudar")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

#Preview {
    ContactDetailView()
}

