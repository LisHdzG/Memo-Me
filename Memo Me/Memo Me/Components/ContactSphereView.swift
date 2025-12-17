//
//  ContactSphereView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import UIKit

/// Universo 2D animado para mostrar los contactos flotando.
/// Mantiene la misma API pública que la versión previa en SceneKit.
struct ContactSphereView: View {
    let contacts: [Contact]
    @Binding var rotationSpeed: Double
    @Binding var isAutoRotating: Bool
    var onContactTapped: ((Contact) -> Void)?
    
    private let glowPalette: [Color] = [
        Color(red: 0.61, green: 0.80, blue: 1.0),
        Color(red: 0.76, green: 0.83, blue: 1.0),
        Color(red: 0.70, green: 0.94, blue: 0.80),
        Color(red: 1.0, green: 0.84, blue: 0.75),
        Color(red: 0.89, green: 0.77, blue: 1.0)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.clear
                
                TimelineView(.animation) { timelineContext in
                    let time = timelineContext.date.timeIntervalSinceReferenceDate
                    let delta: TimeInterval
                    if let last = RotationAccumulator.lastTime {
                        delta = max(0, time - last)
                    } else {
                        delta = 0
                    }
                    RotationAccumulator.lastTime = time
                    
                    if isAutoRotating {
                        RotationAccumulator.accumulatedTime += delta
                    }
                    
                    let baseRotation = RotationAccumulator.accumulatedTime * 0.07 * max(rotationSpeed, 0.25)
                    
                    return AnyView(
                        ZStack {
                            ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                                let config = orbitConfig(for: contact, index: index, in: geo.size)
                                let angle = baseRotation * config.speed + config.phase
                                let x = cos(angle) * config.radius
                                let y = sin(angle) * config.radius * 0.62 + config.verticalOffset
                                
                                ContactBubble(contact: contact, size: config.size, glow: config.glow)
                                    .position(x: geo.size.width / 2 + x, y: geo.size.height / 2 + y)
                                    .contentShape(Circle())
                                    .onTapGesture {
                                        onContactTapped?(contact)
                                    }
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Layout Helpers
    
    private func orbitConfig(for contact: Contact, index: Int, in size: CGSize) -> OrbitConfig {
        let seed = abs(contact.id.hashValue &+ index * 9973)
        let baseRadius = min(size.width, size.height) * 0.32
        let radiusJitter = CGFloat((seed % 45) - 22)
        let radius = max(baseRadius + radiusJitter, baseRadius * 0.7)
        
        let verticalSpread = min(size.height * 0.14, 85)
        let verticalOffset = CGFloat((seed % 160) - 80) / 80 * verticalSpread
        
        let speed = 0.6 + Double(seed % 60) / 120.0
        let phase = Double(seed % 360) * (.pi / 180)
        
        let minSize: CGFloat = 52
        let maxSize: CGFloat = 78
        let sizeValue = minSize + CGFloat(seed % 100) / 100 * (maxSize - minSize)
        
        let glow = glowPalette[seed % glowPalette.count]
        
        return OrbitConfig(radius: radius,
                           verticalOffset: verticalOffset,
                           speed: speed,
                           phase: phase,
                           size: sizeValue,
                           glow: glow)
    }
}

// MARK: - Support Views

private struct ContactBubble: View {
    let contact: Contact
    let size: CGFloat
    let glow: Color
    
    var body: some View {
        let accent = Color(red: 0.63, green: 0.46, blue: 1.0)
        
        VStack(spacing: 6) {
            ZStack {
                ContactAvatar(contact: contact)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.85), lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [5, 5]))
                            .foregroundColor(Color.white.opacity(0.65))
                    )
                    .shadow(color: accent.opacity(0.32), radius: 6, x: 0, y: 3)
                    .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1.2)
                    )
            }
            
            Text(firstName(from: contact.name))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color("SplashTextColor"))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.16), radius: 3, x: 0, y: 2)
        }
    }
    
    private func firstName(from name: String) -> String {
        let parts = name.split(separator: " ")
        return parts.first.map(String.init) ?? name
    }
}

private struct ContactAvatar: View {
    let contact: Contact
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.63, green: 0.46, blue: 1.0))
            
            if let urlString = contact.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        placeholderInitial
                    case .failure:
                        placeholderInitial
                    @unknown default:
                        placeholderInitial
                    }
                }
                .clipShape(Circle())
            } else if let imageName = contact.imageName, !imageName.isEmpty, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                placeholderInitial
            }
        }
        .contentShape(Circle())
    }
    
    private var placeholderInitial: some View {
        let initial = contact.name.first.map { String($0).uppercased() } ?? "?"
        return Circle()
            .fill(Color(red: 0.63, green: 0.46, blue: 1.0))
            .overlay(
                Text(initial)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
    }
}

private struct StarField: View {
    let count: Int
    
    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                for i in 0..<count {
                    let seed = Double(i + 1) * 12.9898
                    let x = CGFloat(truncating: NSNumber(value: sin(seed) * 43758.5453)).truncatingRemainder(dividingBy: size.width)
                    let y = CGFloat(truncating: NSNumber(value: cos(seed) * 12345.6789)).truncatingRemainder(dividingBy: size.height)
                    
                    let twinkle = 0.5 + 0.5 * sin(context.date.timeIntervalSinceReferenceDate * 1.3 + seed)
                    let alpha = 0.18 + 0.35 * twinkle
                    
                    let starRect = CGRect(x: x.normalized(in: size.width),
                                          y: y.normalized(in: size.height),
                                          width: 2.5,
                                          height: 2.5)
                    
                    ctx.fill(Path(ellipseIn: starRect), with: .color(Color.white.opacity(alpha)))
                }
            }
        }
    }
}

// MARK: - Models

private struct OrbitConfig {
    let radius: CGFloat
    let verticalOffset: CGFloat
    let speed: Double
    let phase: Double
    let size: CGFloat
    let glow: Color
}

// MARK: - Helpers

private extension CGFloat {
    func normalized(in dimension: CGFloat) -> CGFloat {
        guard dimension != 0 else { return self }
        let mod = self.truncatingRemainder(dividingBy: dimension)
        return mod < 0 ? mod + dimension : mod
    }
}

// MARK: - Rotation State

private enum RotationAccumulator {
    static var accumulatedTime: TimeInterval = 0
    static var lastTime: TimeInterval?
}
