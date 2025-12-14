//
//  TermsAndConditionsView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI
import SafariServices

struct TermsAndConditionsView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        if #available(iOS 26.0, *) {} else {
            if let tintColor = UIColor(named: "RoyalPurple") {
                safariVC.preferredControlTintColor = tintColor
            }
        }
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
