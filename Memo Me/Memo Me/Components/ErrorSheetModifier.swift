//
//  ErrorSheetModifier.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct ErrorSheetModifier: ViewModifier {
    @ObservedObject private var errorPresenter = ErrorPresenter.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $errorPresenter.showNetworkError) {
                NetworkErrorView()
            }
            .sheet(isPresented: $errorPresenter.showServiceError) {
                ServiceErrorView()
            }
    }
}

extension View {
    func errorSheets() -> some View {
        modifier(ErrorSheetModifier())
    }
}
