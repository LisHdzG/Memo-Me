//
//  LoaderView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct LoaderView: View {
    @ObservedObject private var loaderPresenter: LoaderPresenter = LoaderPresenter.shared
    @State private var isVisible = false
    
    var body: some View {
        if loaderPresenter.isLoading {
            ZStack {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .background(.ultraThinMaterial)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .deepSpace))
                    .scaleEffect(1.8)
                    .frame(width: 60, height: 60)
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                    .scaleEffect(isVisible ? 1.0 : 0.9)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isVisible)
            }
            .transition(.opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation {
                        isVisible = true
                    }
                }
            }
            .onDisappear {
                isVisible = false
            }
        }
    }
}
