//
//  ImagePreviewView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct ImagePreviewOverlay: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Fondo negro sólido
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                        resetZoom()
                    }
                }
            
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if scale < 1.0 {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    } else if scale > 4.0 {
                                        scale = 4.0
                                    }
                                    lastScale = scale
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                
                                // Limitar el desplazamiento cuando está zoomed
                                if scale > 1.0 {
                                    let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                                    let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                                    
                                    offset = CGSize(
                                        width: min(max(newOffset.width, -maxOffsetX), maxOffsetX),
                                        height: min(max(newOffset.height, -maxOffsetY), maxOffsetY)
                                    )
                                } else {
                                    offset = .zero
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if scale > 1.0 {
                                resetZoom()
                            } else {
                                scale = 2.0
                                lastScale = 2.0
                            }
                        }
                    }
            }
            
            // Botón X en la esquina superior izquierda
            VStack {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                            resetZoom()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .transition(.opacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
    
    private func resetZoom() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
        lastScale = 1.0
    }
}

// Mantener la versión anterior para compatibilidad si se usa en otros lugares
struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ImagePreviewOverlay(image: image, isPresented: .constant(true))
    }
}

