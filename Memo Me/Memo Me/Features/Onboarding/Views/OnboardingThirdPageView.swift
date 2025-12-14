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
    @State private var showMascot = false
    @State private var hasAnimated = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryDark)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                HStack(spacing: 8) {
                    AnimatedWord(
                        text: String(localized: "onboarding.page3.word1"),
                        show: showSubtitleWord1,
                        delay: 0.0
                    )
                    AnimatedWord(
                        text: String(localized: "onboarding.page3.word2"),
                        show: showSubtitleWord2,
                        delay: 0.3
                    )
                    AnimatedWord(
                        text: String(localized: "onboarding.page3.word3"),
                        show: showSubtitleWord3,
                        delay: 0.6
                    )
                }
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .frame(minHeight: 40)

                Spacer()

                Text(page.description)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryDark)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .opacity(showDescription ? 1.0 : 0.0)
                    .offset(y: showDescription ? 0 : 30)
                    .scaleEffect(showDescription ? 1.0 : 0.9)
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.7)
                        .delay(0.5),
                        value: showDescription
                    )

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Spacer()

                Image("MemoMeOnboarding")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .opacity(showMascot ? 1.0 : 0.0)
                    .offset(x: showMascot ? 0 : 100)
                    .scaleEffect(showMascot ? 1.0 : 0.8)
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.7)
                        .delay(0.5),
                        value: showMascot
                    )
                    .padding(.trailing, -70)
            }
            .padding(.top, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if !hasAnimated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSubtitleWord1 = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showSubtitleWord2 = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    showSubtitleWord3 = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    showDescription = true
                    showMascot = true
                    hasAnimated = true
                }
            } else {
                showSubtitleWord1 = true
                showSubtitleWord2 = true
                showSubtitleWord3 = true
                showDescription = true
                showMascot = true
            }
        }
    }
}
