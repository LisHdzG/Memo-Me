//
//  QRCodeSheetView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct QRCodeSheetView: View {
    let code: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.ghostWhite)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Text("Space QR Code")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color("DeepSpace"))
                        
                        Text("Share this code to let others join your space")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.primaryDark.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        QRCodeView(code: code, size: 250)
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color("DeepSpace").opacity(0.1), radius: 20, x: 0, y: 10)
                        
                        Text(code)
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color("DeepSpace"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color("DeepSpace").opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = code
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Copy Code")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color("DeepSpace"))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.primaryDark.opacity(0.6))
                    }
                }
            }
        }
    }
}
