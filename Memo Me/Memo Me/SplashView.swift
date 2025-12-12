//
//  SplashView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var showMemo = false
    @State private var showMeReflection = false
    @State private var memoOffset: CGFloat = -30
    @State private var meReflectionOffset: CGFloat = 30
    @State private var imageOpacity: Double = 0
    @State private var imageScale: CGFloat = 0.8
    
    var body: some View {
        if isActive {
            LoginView()
                .transition(.opacity)
        } else {
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
                
                // Contenedor principal centrado verticalmente, alineado a la izquierda
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Texto "Memo" con reflejo alineado a la izquierda
                    VStack(alignment: .leading, spacing: -15) {
                        // "Me" - primera línea
                        Text("Me")
                            .font(.system(size: 110, weight: .bold, design: .rounded))
                            .foregroundColor(Color("SplashTextColor"))
                            .opacity(showMemo ? 1 : 0)
                            .offset(y: showMemo ? 0 : memoOffset)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // "mo" - segunda línea, alineado a la izquierda
                        Text("mo")
                            .font(.system(size: 110, weight: .bold, design: .rounded))
                            .foregroundColor(Color("SplashTextColor"))
                            .opacity(showMemo ? 1 : 0)
                            .offset(y: showMemo ? 0 : memoOffset)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // "Me" reflejado/fadeado con degradado y la imagen al lado
                        HStack(alignment: .top, spacing: 16) {
                            Text("Me")
                                .font(.system(size: 110, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("SplashTextColor").opacity(0.4),
                                            Color("SplashTextColor").opacity(0.1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .opacity(showMeReflection ? 1 : 0)
                                .offset(y: showMeReflection ? 0 : meReflectionOffset)
                            
                            // Imagen MemoMe al lado del último "Me"
                            Image("MemoMe")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                                .opacity(imageOpacity)
                                .scaleEffect(imageScale)
                                .padding(.top, -100)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                    
                    Spacer()
                }
            }
            .onAppear {
                // Secuencia de animaciones
                // 1. Mostrar "Me" y "mo" juntos al mismo tiempo
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showMemo = true
                    memoOffset = 0
                }
                
                // 2. Mostrar "Me" reflejado después de 0.4 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        showMeReflection = true
                        meReflectionOffset = 0
                    }
                }
                
                // 3. Mostrar la imagen después de 0.7 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        imageOpacity = 1.0
                        imageScale = 1.0
                    }
                }
                
                // 4. Transición a la vista principal después de 2.5 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}

