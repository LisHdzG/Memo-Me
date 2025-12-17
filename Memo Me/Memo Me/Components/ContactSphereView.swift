//
//  ContactSphereView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import UIKit

struct ContactSphereView: View {
    let contacts: [Contact]
    @Binding var rotationSpeed: Double
    @Binding var isAutoRotating: Bool
    var onContactTapped: ((Contact) -> Void)?
    var memoProvider: ((Contact) -> Bool)?
    
    private let glowPalette: [Color] = [
        Color(red: 0.61, green: 0.80, blue: 1.0),
        Color(red: 0.76, green: 0.83, blue: 1.0),
        Color(red: 0.70, green: 0.94, blue: 0.80),
        Color(red: 1.0, green: 0.84, blue: 0.75),
        Color(red: 0.89, green: 0.77, blue: 1.0)
    ]
    
    var body: some View {
        GeometryReader { geo in
            rootContent(geoSize: geo.size)
        }
    }
    
    
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
    
    @ViewBuilder
    private func timelineView(geoSize: CGSize) -> some View {
        TimelineView(.animation) { timelineContext in
            let baseRotation = self.computeBaseRotation(from: timelineContext)
            return self.sphereContent(baseRotation: baseRotation, size: geoSize)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: contacts)
    }

    private func rootContent(geoSize: CGSize) -> some View {
        ZStack {
            Color.clear
            timelineView(geoSize: geoSize)
        }
    }
    
    private func computeBaseRotation(from timelineContext: TimelineViewDefaultContext) -> Double {
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
        
        return RotationAccumulator.accumulatedTime * 0.07 * max(rotationSpeed, 0.25)
    }
    
    @ViewBuilder
    private func sphereContent(baseRotation: Double, size: CGSize) -> some View {
        let items = Array(contacts.enumerated())
        
        ZStack {
            ForEach(items, id: \.element.id) { pair in
                let index = pair.offset
                let contact = pair.element
                let config = self.orbitConfig(for: contact, index: index, in: size)
                let angle = baseRotation * config.speed + config.phase
                let x = cos(angle) * config.radius
                let y = sin(angle) * config.radius * 0.62 + config.verticalOffset
                let isMemo = self.memoProvider?(contact) ?? false
                
                ContactBubble(
                    contact: contact,
                    size: config.size,
                    glow: config.glow,
                    isMemo: isMemo,
                    onTap: { self.onContactTapped?(contact) }
                )
                .position(x: size.width / 2 + x, y: size.height / 2 + y)
            }
        }
    }
}


private struct ContactBubble: View {
    let contact: Contact
    let size: CGFloat
    let glow: Color
    let isMemo: Bool
    var onTap: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                ContactAvatar(contact: contact)
                    .frame(width: size, height: size)
                    .contentShape(Circle())
                    .onTapGesture {
                        onTap?()
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.85), lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 2.2, lineCap: .round, dash: [5, 5]))
                            .foregroundColor(Color.white.opacity(0.65))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1.2)
                    )
                    .overlay(alignment: .topTrailing) {
                        if isMemo {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color("DeepSpace"),
                                                Color("DeepSpace").opacity(0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.65), lineWidth: 1.2)
                                    )
                                    .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.white.opacity(0.4), radius: 2, x: 0, y: 0)
                            }
                            .frame(width: 21, height: 21)
                            .offset(x: 6, y: -6)
                        }
                    }
            }
            
            Text(firstName(from: contact.name))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Color("DeepSpace"))
                .allowsHitTesting(false)
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

private struct OrbitConfig {
    let radius: CGFloat
    let verticalOffset: CGFloat
    let speed: Double
    let phase: Double
    let size: CGFloat
    let glow: Color
}


private extension CGFloat {
    func normalized(in dimension: CGFloat) -> CGFloat {
        guard dimension != 0 else { return self }
        let mod = self.truncatingRemainder(dividingBy: dimension)
        return mod < 0 ? mod + dimension : mod
    }
}


private enum RotationAccumulator {
    static var accumulatedTime: TimeInterval = 0
    static var lastTime: TimeInterval?
}
