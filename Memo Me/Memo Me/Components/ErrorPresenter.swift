//
//  ErrorPresenter.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI
import Combine

class ErrorPresenter: ObservableObject {
    static let shared = ErrorPresenter()
    
    @Published var showNetworkError = false
    @Published var showServiceError = false
    @Published var retryAction: (() -> Void)?
    
    private init() {}
    
    @MainActor
    func showNetworkError(retry: (() -> Void)? = nil) {
        self.retryAction = retry
        self.showNetworkError = true
    }
    
    @MainActor
    func showServiceError(retry: (() -> Void)? = nil) {
        self.retryAction = retry
        self.showServiceError = true
    }
    
    @MainActor
    func dismiss() {
        showNetworkError = false
        showServiceError = false
        retryAction = nil
    }
    
    @MainActor
    func retry() {
        retryAction?()
    }
}
