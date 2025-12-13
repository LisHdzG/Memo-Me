//
//  Custom3DPicker.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

/// Vista del Picker 3D personalizado
fileprivate struct Custom3DPickerView: View {
    var items: [String]
    @Binding var config: PickerConfig
    @Binding var isPresented: Bool
    
    /// Propiedades privadas de la vista
    @State private var activeItem: String?
    @State private var showContents: Bool = false
    @State private var showScrollView: Bool = false
    @State private var expandItems: Bool = false
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ZStack {
                // Fondo semitransparente que deja ver lo de abajo
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("PurpleGradientTop").opacity(0.95),
                        Color("PurpleGradientMiddle").opacity(0.95),
                        Color("PurpleGradientBottom").opacity(0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ScrollView con los items
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(items, id: \.self) { item in
                                CardView(item, size: size)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    /// Hacer que empiece y termine en el centro
                    .safeAreaPadding(.top, (size.height * 0.5) - 20)
                    .safeAreaPadding(.bottom, (size.height * 0.5) + 80) // Espacio para el botón
                    .scrollPosition(id: $activeItem, anchor: .center)
                    .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                    .scrollIndicators(.hidden)
                    .opacity(showScrollView ? 1 : 0)
                    .allowsHitTesting(expandItems && showScrollView)
                    
                    // Botón de seleccionar en la parte inferior
                    VStack {
                        Button(action: {
                            // Confirmar selección y cerrar
                            Task {
                                // Cerrar con animación
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    expandItems = false
                                }
                                
                                try? await Task.sleep(for: .seconds(0.2))
                                showScrollView = false
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showContents = false
                                }
                                
                                try? await Task.sleep(for: .seconds(0.2))
                                config.show = false
                                isPresented = false
                            }
                        }) {
                            HStack {
                                Text("Seleccionar")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
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
                        .padding(.bottom, 40)
                    }
                    .opacity(showScrollView ? 1 : 0)
                }
            }
            
            // Offset para la animación (simplificado para fullScreen)
            let offset: CGSize = .init(
                width: showContents ? size.width * -0.3 : 0,
                height: showContents ? 0 : 0
            )
            
            // Texto seleccionado con animación (oculto en fullScreen)
            Text(config.text)
                .fontWeight(showContents ? .semibold : .regular)
                .foregroundStyle(.white)
                .frame(height: 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: showContents ? .trailing : .topLeading)
                .offset(offset)
                .opacity(0) // Oculto en fullScreen
                .ignoresSafeArea(.all, edges: showContents ? [] : .all)
            
        }
        .onAppear {
            // Inicializar cuando aparece
            if activeItem == nil {
                activeItem = config.text
            }
            
            // Iniciar animaciones
            Task {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showContents = true
                }
                
                try? await Task.sleep(for: .seconds(0.3))
                showScrollView = true
                
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    expandItems = true
                }
            }
        }
        .onChange(of: activeItem) { oldValue, newValue in
            if let newValue {
                config.text = newValue
            }
        }
    }
    
    /// Vista de tarjeta para cada item
    @ViewBuilder
    private func CardView(_ text: String, size: CGSize) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            
            Text(text)
                .fontWeight(.semibold)
                .foregroundStyle(config.text == text ? .white : .white.opacity(0.6))
                .blur(radius: expandItems ? 0 : config.text == text ? 0 : 5)
                .offset(y: offset(proxy))
                .clipped()
                .offset(x: -width * 0.3)
                .rotationEffect(.init(degrees: expandItems ? -rotation(proxy, size) : .zero), anchor: .topTrailing)
                .opacity(opacity(proxy, size))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .frame(height: 20)
        .lineLimit(1)
        .zIndex(config.text == text ? 1000 : 0)
    }
    
    /// Helpers para transiciones de vista
    private func offset(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return expandItems ? 0 : -minY
    }
    
    private func rotation(_ proxy: GeometryProxy, _ size: CGSize) -> CGFloat {
        let height = size.height * 0.5
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        /// Puedes ajustar este valor para más o menos rotación
        let maxRotation: CGFloat = 220
        let progress = minY / height
        
        return progress * maxRotation
    }
    
    private func opacity(_ proxy: GeometryProxy, _ size: CGSize) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let height = size.height * 0.5
        let progress = (minY / height) * 2.8
        /// Eliminando opacidad negativa
        let opacity = progress < 0 ? 1 + progress : 1 - progress
        
        return opacity
    }
}

/// Extensión para usar el picker como modificador - overlay semitransparente
extension View {
    @ViewBuilder
    func custom3DPicker(_ config: Binding<PickerConfig>, items: [String], isPresented: Binding<Bool>) -> some View {
        self
            .overlay {
                if config.wrappedValue.show {
                    Custom3DPickerView(items: items, config: config, isPresented: isPresented)
                        .transition(.opacity)
                }
            }
    }
}

