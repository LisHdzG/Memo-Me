//
//  OnboardingFirstPageView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct OnboardingFirstPageView: View {
    let page: OnboardingPage

    @State private var animateText = false
    @State private var hasAnimated = false

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

            subtitleText
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 48)
                .padding(.top, -20)
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: animateText)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if !hasAnimated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        animateText = true
                        hasAnimated = true
                    }
                }
            } else {
                animateText = true
            }
        }
    }

    private var subtitleText: some View {
        let subtitle = page.subtitle
        let lines = subtitle.components(separatedBy: "\n")

        let firstLineFinalSize: CGFloat = 20
        let secondLineFinalSize: CGFloat = 25

        guard lines.count == 2 else {
            return AnyView(
                Text(subtitle)
                    .font(.system(size: firstLineFinalSize, weight: .medium, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.75))
            )
        }

        let firstLine = lines[0]
        let secondLine = lines[1]
        let boldKeywords = ["MemoME", "stories", "historias", "storie"]

        var combinedAttributed = AttributedString(firstLine)
        combinedAttributed.font = .system(size: firstLineFinalSize, weight: .medium, design: .rounded)
        combinedAttributed.foregroundColor = .primaryDark.opacity(0.75)

        let newlineAttributed = AttributedString("\n")
        combinedAttributed.append(newlineAttributed)

        let nsString = secondLine as NSString
        let options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

        var keywordRanges: [(NSRange, String)] = []
        var usedRanges: [NSRange] = []

        for keyword in boldKeywords {
            var searchRange = NSRange(location: 0, length: nsString.length)
            while searchRange.location < nsString.length {
                let foundRange = nsString.range(of: keyword, options: options, range: searchRange)
                if foundRange.location != NSNotFound {
                    let overlaps = usedRanges.contains { usedRange in
                        NSIntersectionRange(foundRange, usedRange).length > 0
                    }

                    if !overlaps {
                        keywordRanges.append((foundRange, keyword))
                        usedRanges.append(foundRange)
                    }

                    searchRange.location = foundRange.location + foundRange.length
                    searchRange.length = nsString.length - searchRange.location
                } else {
                    break
                }
            }
        }

        keywordRanges.sort { $0.0.location < $1.0.location }

        var secondLineAttributed = AttributedString()
        var currentIndex = 0

        for (range, _) in keywordRanges {
            if range.location > currentIndex {
                let before = nsString.substring(
                    with: NSRange(location: currentIndex, length: range.location - currentIndex)
                )
                var beforeAttr = AttributedString(before)
                beforeAttr.font = .system(
                    size: animateText ? secondLineFinalSize : firstLineFinalSize,
                    weight: .regular,
                    design: .rounded
                )
                beforeAttr.foregroundColor = .primaryDark.opacity(0.75)
                secondLineAttributed.append(beforeAttr)
            }

            let keywordText = nsString.substring(with: range)
            var keywordAttr = AttributedString(keywordText)
            keywordAttr.font = .system(
                size: animateText ? secondLineFinalSize : firstLineFinalSize,
                weight: .bold,
                design: .rounded
            )
            keywordAttr.foregroundColor = .primaryDark.opacity(0.9)
            secondLineAttributed.append(keywordAttr)

            currentIndex = range.location + range.length
        }

        if currentIndex < nsString.length {
            let after = nsString.substring(from: currentIndex)
            var afterAttr = AttributedString(after)
            afterAttr.font = .system(
                size: animateText ? secondLineFinalSize : firstLineFinalSize,
                weight: .regular,
                design: .rounded
            )
            afterAttr.foregroundColor = .primaryDark.opacity(0.75)
            secondLineAttributed.append(afterAttr)
        }

        if keywordRanges.isEmpty {
            secondLineAttributed = AttributedString(secondLine)
            secondLineAttributed.font = .system(
                size: animateText ? secondLineFinalSize : firstLineFinalSize,
                weight: .regular,
                design: .rounded
            )
            secondLineAttributed.foregroundColor = .primaryDark.opacity(0.75)
        }

        combinedAttributed.append(secondLineAttributed)

        return AnyView(
            Text(combinedAttributed)
                .lineLimit(2)
        )
    }
}
