//
//  AsyncImageView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct AsyncImageView: View {
    let imageUrl: String?
    let placeholderText: String
    let contentMode: ContentMode
    let size: CGFloat
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: size, height: size)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("PurpleGradientTop").opacity(0.6),
                                    Color("PurpleGradientMiddle").opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(String(placeholderText.prefix(1)))
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: imageUrl) { _, _ in
            Task {
                await loadImage()
            }
        }
    }
    
    private func loadImage() async {
        guard let imageUrl = imageUrl, !imageUrl.isEmpty else {
            loadedImage = nil
            isLoading = false
            return
        }
        
        isLoading = true
        
        if let image = await ImageLoaderService.shared.loadImage(from: imageUrl) {
            loadedImage = image
        } else {
            loadedImage = nil
        }
        
        isLoading = false
    }
}
