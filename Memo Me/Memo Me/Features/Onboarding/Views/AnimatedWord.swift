//
//  AnimatedWord.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct AnimatedWord: View {
    let text: String
    let show: Bool
    let delay: Double

    var body: some View {
        Text(text)
            .opacity(show ? 1.0 : 0.0)
            .offset(y: show ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: show)
    }
}
