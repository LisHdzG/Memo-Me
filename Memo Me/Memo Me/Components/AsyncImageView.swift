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
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .frame(width: size, height: size)
            } else {
                // Placeholder estilo Apple: círculo claro con la primera letra
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: size, height: size)
                    
                    Text(String(placeholderText.prefix(1)).uppercased())
                        .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                        .foregroundColor(.primaryDark.opacity(0.6))
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
            return
        }
        
        if let image = await ImageLoaderService.shared.loadImage(from: imageUrl) {
            loadedImage = image
        } else {
            loadedImage = nil
        }
    }
}
