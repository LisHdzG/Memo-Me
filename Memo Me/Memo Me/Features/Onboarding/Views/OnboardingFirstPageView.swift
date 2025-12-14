//
//  OnboardingFirstPageView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct OnboardingFirstPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 20) {
            Text(page.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(purpleColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Text(page.subtitle)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(purpleColor.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var purpleColor: Color {
        Color("PurpleGradientTop")
    }
}
