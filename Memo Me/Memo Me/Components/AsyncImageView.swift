//
//  AsyncImageView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI
import Combine

struct AsyncImageView: View {
    let imageUrl: String?
    let placeholderText: String?
    let contentMode: ContentMode
    let size: CGFloat
    
    @StateObject private var imageLoader = ImageLoaderViewModel()
    
    init(
        imageUrl: String?,
        placeholderText: String? = nil,
        contentMode: ContentMode = .fill,
        size: CGFloat = 120
    ) {
        self.imageUrl = imageUrl
        self.placeholderText = placeholderText
        self.contentMode = contentMode
        self.size = size
    }
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholderView
            }
        }
        .task {
            await imageLoader.loadImage(from: imageUrl)
        }
        .onChange(of: imageUrl) { oldValue, newValue in
            Task {
                await imageLoader.loadImage(from: newValue)
            }
        }
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        Circle()
            .fill(Color.white.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Group {
                    if let initial = placeholderText?.prefix(1).uppercased(), !initial.isEmpty {
                        Text(initial)
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            )
    }
}

@MainActor
class ImageLoaderViewModel: ObservableObject {
    @Published var image: UIImage?
    
    private let imageLoader = ImageLoaderService.shared
    
    func loadImage(from urlString: String?) async {
        guard let urlString = urlString else {
            image = nil
            return
        }
        
        image = await imageLoader.loadImage(from: urlString)
    }
}
