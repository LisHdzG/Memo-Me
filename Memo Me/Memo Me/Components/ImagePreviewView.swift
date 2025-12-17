//
//  ImagePreviewView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI
import UIKit

struct ImagePreviewOverlay: View {
    let image: UIImage?
    let imageUrl: String?
    let placeholderText: String?
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var displayedImage: UIImage?
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            Color("GhostWhite")
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                        resetZoom()
                    }
                }
            
            GeometryReader { geometry in
                ZStack {
                    if let displayedImage {
                        Image(uiImage: displayedImage)
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
                    } else {
                        VStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .tint(Color("DeepSpace"))
                            } else {
                                Image(systemName: "photo")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundColor(Color("DeepSpace").opacity(0.55))
                            }
                            
                            if let placeholderText, !placeholderText.isEmpty {
                                Text(placeholderText)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.primaryDark.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .transition(.opacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        .onAppear {
            if displayedImage == nil {
                loadImage()
            }
        }
    }
    
    private func resetZoom() {
        scale = 1.0
        offset = .zero
        lastOffset = .zero
        lastScale = 1.0
    }
    
    private func loadImage() {
        if let image {
            displayedImage = image
            return
        }
        
        guard let imageUrl = imageUrl else { return }
        
        isLoading = true
        Task {
            let loadedImage = await ImageLoaderService.shared.loadImage(from: imageUrl)
            await MainActor.run {
                displayedImage = loadedImage
                isLoading = false
            }
        }
    }
}

struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ImagePreviewOverlay(image: image, imageUrl: nil, placeholderText: nil, isPresented: .constant(true))
    }
}

