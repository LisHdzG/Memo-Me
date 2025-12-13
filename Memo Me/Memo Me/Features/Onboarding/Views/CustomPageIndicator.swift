//
//  CustomPageIndicator.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

struct CustomPageIndicator: View {
    let totalPages: Int
    let currentPage: Int
    let activeColor: Color
    let inactiveColor: Color
    
    private let dashWidth: CGFloat = 24
    private let dotSize: CGFloat = 6
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                if index == currentPage {
                    // Dash activo (más largo)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(activeColor)
                        .frame(width: dashWidth, height: 4)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                } else {
                    // Punto inactivo
                    Circle()
                        .fill(inactiveColor)
                        .frame(width: dotSize, height: dotSize)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
    }
}

