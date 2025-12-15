//
//  ServiceErrorView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct ServiceErrorView: View {
    @ObservedObject private var errorPresenter: ErrorPresenter = ErrorPresenter.shared
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image("MemoMeError")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 150)
            
            Text("Service Error")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primaryDark)
                .multilineTextAlignment(.center)
            
            Text("Something went wrong with the service. Please try again in a moment.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()
            Button {
                errorPresenter.retry()
            } label: {
                Text("Retry")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.deepSpace)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.hidden)
        .presentationBackground {
            Color.white
        }
    }
}
