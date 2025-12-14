//
//  OnboardingSecondPageView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct OnboardingSecondPageView: View {
    let page: OnboardingPage

    var body: some View {
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
                .frame(height: 40)

            Text(page.subtitle)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 48)

            Spacer()

            if !page.description.isEmpty {
                descriptionText
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 48)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var descriptionText: some View {
        let description = page.description
        let boldPhrases = [
            "has its place",
            "tiene un lugar",
            "ha il suo posto"
        ]

        guard let phrase = boldPhrases.first(where: { phrase in
            description.localizedCaseInsensitiveContains(phrase)
        }) else {
            return AnyView(
                Text(description)
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.75))
            )
        }

        let nsString = description as NSString
        let options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let range = nsString.range(of: phrase, options: options)

        guard range.location != NSNotFound else {
            return AnyView(
                Text(description)
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.75))
            )
        }

        let before = nsString.substring(to: range.location)
        let phraseText = nsString.substring(with: range)
        let after = nsString.substring(from: range.location + range.length)

        var attributedString = AttributedString(before)
        attributedString.font = .system(size: 25, weight: .medium, design: .rounded)
        attributedString.foregroundColor = .primaryDark.opacity(0.75)

        var phraseAttributed = AttributedString(phraseText)
        phraseAttributed.font = .system(size: 27, weight: .bold, design: .rounded)
        phraseAttributed.foregroundColor = .primaryDark.opacity(0.9)

        var afterAttributed = AttributedString(after)
        afterAttributed.font = .system(size: 25, weight: .medium, design: .rounded)
        afterAttributed.foregroundColor = .primaryDark.opacity(0.75)

        attributedString.append(phraseAttributed)
        attributedString.append(afterAttributed)

        return AnyView(
            Text(attributedString)
        )
    }
}
