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
    @State private var showCopiedToast = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                        qrCard
                        actionButtons
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, 32)
                }
            }
            .overlay(alignment: .bottom) {
                if showCopiedToast {
                    copiedToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 18)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showCopiedToast)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            Text("Space QR Code")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("DeepSpace"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Share this code so others can join the space.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var qrCard: some View {
        VStack(spacing: 18) {
            HStack {
                Label("Scan and join", systemImage: "qrcode.viewfinder")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("DeepSpace"))
                Spacer()
                Text("Secure • Fast")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.55))
            }
            
            QRCodeView(code: code, size: 240)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color("DeepSpace").opacity(0.12), radius: 16, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color("DeepSpace").opacity(0.18),
                                            Color("DeepSpace").opacity(0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        )
                )
            
            VStack(spacing: 8) {
                Text("Space code")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.6))
                Text(code)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("DeepSpace"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color("DeepSpace").opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color("DeepSpace").opacity(0.08), radius: 18, x: 0, y: 6)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: copyCode) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Copy code")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color("DeepSpace"), Color("DeepSpace").opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color("DeepSpace").opacity(0.18), radius: 10, x: 0, y: 6)
            }
            
            ShareLink(item: code) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Share")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Color("DeepSpace"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color("DeepSpace").opacity(0.12), radius: 10, x: 0, y: 6)
            }
        }
    }
    
    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color("DeepSpace").opacity(0.08),
                Color(.ghostWhite)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            ZStack {
                Circle()
                    .fill(Color("DeepSpace").opacity(0.18))
                    .blur(radius: 90)
                    .frame(width: 220, height: 220)
                    .offset(x: -120, y: -180)
                Circle()
                    .fill(Color("RoyalPurple").opacity(0.12))
                    .blur(radius: 120)
                    .frame(width: 260, height: 260)
                    .offset(x: 140, y: 220)
            }
        )
    }
    
    private var copiedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Text("Code copied")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color("DeepSpace").opacity(0.9))
        .cornerRadius(14)
        .shadow(color: Color("DeepSpace").opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    private func copyCode() {
        UIPasteboard.general.string = code
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation {
                showCopiedToast = false
            }
        }
    }
}
