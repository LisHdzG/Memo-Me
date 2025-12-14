//
//  LoaderPresenter.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI
import Foundation
import Combine

class LoaderPresenter: ObservableObject {
    static let shared = LoaderPresenter()
    
    @Published var isLoading = false
    
    private init() {}
    
    @MainActor
    func show() {
        isLoading = true
    }
    
    @MainActor
    func hide() {
        isLoading = false
    }
}
