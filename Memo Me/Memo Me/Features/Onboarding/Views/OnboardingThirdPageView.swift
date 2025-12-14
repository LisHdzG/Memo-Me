//
//  OnboardingThirdPageView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct OnboardingThirdPageView: View {
    let page: OnboardingPage

    @State private var showSubtitleWord1 = false
    @State private var showSubtitleWord2 = false
    @State private var showSubtitleWord3 = false
    @State private var showDescription = false

    var body: some View {
        VStack(spacing: 24) {
            Text(page.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(purpleColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            HStack(spacing: 8) {
                AnimatedWord(text: "Contexto.", show: showSubtitleWord1, delay: 0.0)
                AnimatedWord(text: "Personas.", show: showSubtitleWord2, delay: 0.3)
                AnimatedWord(text: "Memoria.", show: showSubtitleWord3, delay: 0.6)
            }
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundColor(purpleColor.opacity(0.9))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .frame(minHeight: 30)

            Text(page.description)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(purpleColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(showDescription ? 1.0 : 0.0)
                .offset(y: showDescription ? 0 : 60)
                .scaleEffect(showDescription ? 1.0 : 0.8)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.6)
                    .delay(1.0),
                    value: showDescription
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            showSubtitleWord1 = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showSubtitleWord2 = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                showSubtitleWord3 = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showDescription = true
            }
        }
        .onDisappear {
            showSubtitleWord1 = false
            showSubtitleWord2 = false
            showSubtitleWord3 = false
            showDescription = false
        }
    }

    private var purpleColor: Color {
        Color("PurpleGradientTop")
    }
}
