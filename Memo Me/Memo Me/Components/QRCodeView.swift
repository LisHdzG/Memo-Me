//
//  QRCodeView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let code: String
    let size: CGFloat
    
    init(code: String, size: CGFloat = 200) {
        self.code = code
        self.size = size
    }
    
    var body: some View {
        ZStack {
            if let qrImage = generateQRCode(from: code) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: size, height: size)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.orange)
                            Text("Unable to generate QR code")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }
                    )
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        guard let data = cleaned.data(using: .utf8) else { return nil }
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        
        let transform = CGAffineTransform(scaleX: 7, y: 7)
        
        guard let outputImage = filter.outputImage?.transformed(by: transform) else {
            return nil
        }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

