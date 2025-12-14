//
//  AnimatedPeopleCirclesView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

struct AnimatedPeopleCirclesView: View {
    @State private var circles: [AnimatedCircle] = []
    @State private var animationTask: Task<Void, Never>?
    @State private var containerSize: CGSize = .zero
    
    let totalPeople = 20 // Total de personas disponibles
    let visiblePeople = 10 // Personas visibles a la vez
    let minSize: CGFloat = 50
    let maxSize: CGFloat = 100
    
    // Nombres de imágenes locales de assets (20 personas)
    private let dummyImageNames: [String] = {
        (1...20).map { String(format: "DummyProfile%02d", $0) }
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(circles) { circle in
                    if circle.isVisible {
                        PersonCircleView(
                            imageName: circle.imageName,
                            size: circle.size,
                            scale: circle.scale
                        )
                        .position(circle.position)
                        .opacity(circle.opacity)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .onAppear {
                containerSize = geometry.size
                initializeCircles(in: geometry.size)
                startAnimations()
            }
            .onDisappear {
                stopAnimations()
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                containerSize = newSize
                // Reajustar círculos si cambia el tamaño
                if !circles.isEmpty {
                    adjustCirclesToNewSize(newSize)
                }
            }
        }
    }
    
    private func initializeCircles(in size: CGSize) {
        // Crear 20 círculos pero solo hacer visibles los primeros 10
        circles = (0..<totalPeople).map { index in
            let randomSize = CGFloat.random(in: minSize...maxSize)
            let margin = maxSize / 2 + 10
            let randomX = CGFloat.random(in: margin...(max(size.width - margin, margin * 2)))
            let randomY = CGFloat.random(in: margin...(max(size.height - margin, margin * 2)))
            let imageName = dummyImageNames[index]
            
            return AnimatedCircle(
                id: UUID(),
                position: CGPoint(x: randomX, y: randomY),
                size: randomSize,
                opacity: index < visiblePeople ? 1.0 : 0.0, // Solo los primeros 10 visibles
                targetPosition: CGPoint(x: randomX, y: randomY),
                targetSize: randomSize,
                velocity: CGPoint(
                    x: CGFloat.random(in: -40...40), // Velocidad más rápida
                    y: CGFloat.random(in: -40...40)
                ),
                imageName: imageName,
                isVisible: index < visiblePeople,
                scale: index < visiblePeople ? 1.0 : 0.0,
                animationState: index < visiblePeople ? .visible : .hidden
            )
        }
    }
    
    private func adjustCirclesToNewSize(_ newSize: CGSize) {
        let margin = maxSize / 2 + 10
        for index in circles.indices {
            var circle = circles[index]
            // Ajustar posición si está fuera de los límites
            circle.position.x = max(margin, min(newSize.width - margin, circle.position.x))
            circle.position.y = max(margin, min(newSize.height - margin, circle.position.y))
            circles[index] = circle
        }
    }
    
    private func startAnimations() {
        animationTask = Task {
            while !Task.isCancelled {
                await MainActor.run {
                    updateCircles()
                }
                try? await Task.sleep(nanoseconds: 30_000_000) // 0.03 segundos
            }
        }
    }
    
    private func stopAnimations() {
        animationTask?.cancel()
        animationTask = nil
    }
    
    private func updateCircles() {
        guard containerSize.width > 0 && containerSize.height > 0 else { return }
        
        let margin = maxSize / 2
        let maxX = containerSize.width - margin
        let maxY = containerSize.height - margin
        let minX = margin
        let minY = margin
        
        // Contar personas visibles
        var currentlyVisible = circles.filter { $0.isVisible && $0.animationState == .visible }.count
        
        // Primero, manejar las que están desapareciendo o apareciendo
        for index in circles.indices {
            var circle = circles[index]
            
            switch circle.animationState {
            case .disappearing:
                // Continuar desapareciendo
                circle.scale -= 0.25
                circle.opacity -= 0.25
                if circle.scale <= 0.0 {
                    circle.scale = 0.0
                    circle.opacity = 0.0
                    circle.isVisible = false
                    circle.animationState = .hidden
                    currentlyVisible -= 1
                    
                    // Inmediatamente hacer aparecer otra para mantener 10 visibles
                    if let hiddenIndex = circles.firstIndex(where: { !$0.isVisible && $0.animationState == .hidden }) {
                        var newCircle = circles[hiddenIndex]
                        newCircle.position = CGPoint(
                            x: CGFloat.random(in: minX...maxX),
                            y: CGFloat.random(in: minY...maxY)
                        )
                        newCircle.size = CGFloat.random(in: minSize...maxSize)
                        newCircle.targetSize = newCircle.size
                        newCircle.velocity = CGPoint(
                            x: CGFloat.random(in: -40...40),
                            y: CGFloat.random(in: -40...40)
                        )
                        // Seleccionar una imagen aleatoria que no esté siendo usada por las visibles
                        let visibleImages = Set(circles.filter { $0.isVisible && $0.animationState == .visible }.map { $0.imageName })
                        let availableImages = dummyImageNames.filter { !visibleImages.contains($0) }
                        newCircle.imageName = availableImages.randomElement() ?? dummyImageNames.randomElement() ?? dummyImageNames[0]
                        newCircle.scale = 0.0
                        newCircle.opacity = 0.0
                        newCircle.animationState = .appearing
                        circles[hiddenIndex] = newCircle
                    }
                }
            case .appearing:
                // Efecto "plop!" tipo burbuja que se revienta - crecer rápidamente
                if circle.scale < 1.5 {
                    // Crecer hasta 1.5x (más dramático)
                    circle.scale += 0.4
                    circle.opacity = min(1.0, circle.opacity + 0.3)
                } else {
                    // Reventar y volver al tamaño normal rápidamente
                    circle.scale -= 0.3
                    if circle.scale <= 1.0 {
                        circle.scale = 1.0
                        circle.opacity = 1.0
                        circle.isVisible = true
                        circle.animationState = .visible
                        currentlyVisible += 1
                    }
                }
            default:
                break
            }
            
            circles[index] = circle
        }
        
        // Si hay menos de 10 visibles y ninguna está apareciendo, hacer aparecer una
        let appearingCount = circles.filter { $0.animationState == .appearing }.count
        if currentlyVisible + appearingCount < visiblePeople {
            if let hiddenIndex = circles.firstIndex(where: { !$0.isVisible && $0.animationState == .hidden }) {
                var circle = circles[hiddenIndex]
                circle.position = CGPoint(
                    x: CGFloat.random(in: minX...maxX),
                    y: CGFloat.random(in: minY...maxY)
                )
                circle.size = CGFloat.random(in: minSize...maxSize)
                circle.targetSize = circle.size
                circle.velocity = CGPoint(
                    x: CGFloat.random(in: -40...40),
                    y: CGFloat.random(in: -40...40)
                )
                // Seleccionar una imagen aleatoria que no esté siendo usada
                let visibleImages = Set(circles.filter { $0.isVisible && $0.animationState == .visible }.map { $0.imageName })
                let availableImages = dummyImageNames.filter { !visibleImages.contains($0) }
                circle.imageName = availableImages.randomElement() ?? dummyImageNames.randomElement() ?? dummyImageNames[0]
                circle.scale = 0.0
                circle.opacity = 0.0
                circle.animationState = .appearing
                circles[hiddenIndex] = circle
            }
        }
        
        // Ocasionalmente hacer desaparecer una persona visible para mantener la rotación
        if currentlyVisible >= visiblePeople && Int.random(in: 0...400) < 2 {
            if let visibleIndex = circles.indices.randomElement(),
               circles[visibleIndex].isVisible && circles[visibleIndex].animationState == .visible {
                circles[visibleIndex].animationState = .disappearing
            }
        }
        
        // Actualizar posiciones de las personas visibles
        for index in circles.indices {
            var circle = circles[index]
            
            if circle.animationState == .visible {
                circle.position.x += circle.velocity.x * 0.05 // Movimiento más rápido
                circle.position.y += circle.velocity.y * 0.05
                
                // Rebotar en los bordes
                if circle.position.x < minX || circle.position.x > maxX {
                    circle.velocity.x *= -1
                }
                if circle.position.y < minY || circle.position.y > maxY {
                    circle.velocity.y *= -1
                }
                
                // Mantener dentro de los límites
                circle.position.x = max(minX, min(maxX, circle.position.x))
                circle.position.y = max(minY, min(maxY, circle.position.y))
                
                // Cambiar tamaño ocasionalmente
                if Int.random(in: 0...200) < 2 {
                    circle.targetSize = CGFloat.random(in: minSize...maxSize)
                }
                
                // Animar hacia el tamaño objetivo
                if abs(circle.size - circle.targetSize) > 2 {
                    circle.size += (circle.targetSize - circle.size) * 0.15
                }
                
                // Cambiar dirección ocasionalmente
                if Int.random(in: 0...400) < 2 {
                    circle.velocity = CGPoint(
                        x: CGFloat.random(in: -40...40),
                        y: CGFloat.random(in: -40...40)
                    )
                }
            }
            
            circles[index] = circle
        }
    }
}

enum CircleAnimationState {
    case hidden
    case appearing
    case visible
    case disappearing
}

struct AnimatedCircle: Identifiable {
    let id: UUID
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var targetPosition: CGPoint
    var targetSize: CGFloat
    var velocity: CGPoint
    var imageName: String
    var isVisible: Bool
    var scale: CGFloat
    var animationState: CircleAnimationState
}

struct PersonCircleView: View {
    let imageName: String
    let size: CGFloat
    let scale: CGFloat
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
            )
            .scaleEffect(scale)
            .animation(.spring(response: 0.3, dampingFraction: 0.4), value: scale)
    }
}
