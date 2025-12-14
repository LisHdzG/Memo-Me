//
//  AnimatedPeopleCirclesView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import SwiftUI

enum AnimationMode {
    case free
    case grouped
    case exiting
}

struct AnimatedPeopleCirclesView: View {
    let currentPage: Int
    let baseOpacity: Double

    @State private var circles: [AnimatedCircle] = []
    @State private var containerSize: CGSize = .zero
    @State private var savedFreePositions: [CGPoint] = []
    @State private var savedGroupedPositions: [CGPoint] = []

    let totalPeople = 20
    let minSize: CGFloat = 40
    let maxSize: CGFloat = 110

    private let dummyImageNames: [String] = {
        (1...20).map { String(format: "DummyProfile%02d", $0) }
    }()

    init(currentPage: Int, baseOpacity: Double = 0.3) {
        self.currentPage = currentPage
        self.baseOpacity = baseOpacity
    }

    private var mode: AnimationMode {
        switch currentPage {
        case 0:
            return .free
        case 1:
            return .grouped
        default:
            return .exiting
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(circles) { circle in
                    PersonCircleView(
                        imageName: circle.imageName,
                        size: circle.size,
                        scale: circle.scale,
                        isGrouped: mode == .grouped
                    )
                    .position(circle.position)
                    .opacity(circle.opacity * baseOpacity)
                    .animation(.spring(response: 1.2, dampingFraction: 0.8), value: circle.position)
                    .animation(.easeInOut(duration: 0.8), value: circle.opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .onAppear {
                containerSize = geometry.size
            }
            .task {
                try? await Task.sleep(nanoseconds: 50_000_000)
                if containerSize.width > 0 && containerSize.height > 0 && circles.isEmpty {
                    initializeCircles(in: containerSize)
                }
            }
            .task(id: currentPage) {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if containerSize.width > 0 && containerSize.height > 0 {
                    if circles.isEmpty {
                        initializeCircles(in: containerSize)
                    }
                }
            }
            .onChange(of: currentPage) { oldPage, newPage in
                let newMode: AnimationMode = {
                    switch newPage {
                    case 0: return .free
                    case 1: return .grouped
                    default: return .exiting
                    }
                }()
                let oldMode: AnimationMode = {
                    switch oldPage {
                    case 0: return .free
                    case 1: return .grouped
                    default: return .exiting
                    }
                }()

                if newMode != oldMode {
                    withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                        transitionToMode(newMode, in: geometry.size)
                    }
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                containerSize = newSize
                if circles.isEmpty && newSize.width > 0 && newSize.height > 0 {
                    initializeCircles(in: newSize)
                } else if !circles.isEmpty {
                    adjustCirclesToNewSize(newSize)
                }
            }
        }
    }

    private func initializeCircles(in size: CGSize) {
        switch mode {
        case .free:
            initializeFreeMode(in: size)
        case .grouped:
            initializeGroupedMode(in: size)
        case .exiting:
            initializeExitingMode(in: size)
        }
    }

    private func initializeFreeMode(in size: CGSize) {
        if !savedFreePositions.isEmpty && !circles.isEmpty {
            return
        }

        let margin: CGFloat = 20
        let minX = margin
        let minY = margin
        let maxX = size.width - margin
        let maxY = size.height - margin

        guard maxX > minX && maxY > minY else {
            circles = []
            return
        }

        var usedPositions: [CGPoint] = []
        let minDistance: CGFloat = 40

        circles = (0..<totalPeople).map { index in
            let sizeRange: [CGFloat] = [
                minSize,
                minSize + 10,
                minSize + 20,
                minSize + 30,
                minSize + 40,
                minSize + 50,
                minSize + 60,
                maxSize
            ]
            let randomSize = sizeRange.randomElement() ?? CGFloat.random(in: minSize...maxSize)
            let imageName = dummyImageNames[index]

            var attempts = 0
            var position: CGPoint
            repeat {
                position = CGPoint(
                    x: CGFloat.random(in: minX...maxX),
                    y: CGFloat.random(in: minY...maxY)
                )
                attempts += 1

                if attempts > 20 {
                    break
                }
            } while usedPositions.contains { existingPos in
                let distance = sqrt(
                    pow(position.x - existingPos.x, 2) +
                    pow(position.y - existingPos.y, 2)
                )
                return distance < minDistance
            }

            usedPositions.append(position)

            return AnimatedCircle(
                id: UUID(),
                position: position,
                size: randomSize,
                opacity: 1.0,
                imageName: imageName,
                isVisible: true,
                scale: 1.0
            )
        }

        savedFreePositions = circles.map { $0.position }
    }

    private func initializeGroupedMode(in size: CGSize) {
        if !savedGroupedPositions.isEmpty && savedGroupedPositions.count == circles.count {
            for index in circles.indices {
                var circle = circles[index]
                circle.position = savedGroupedPositions[index]
                circle.opacity = 1.0
                circles[index] = circle
            }
            return
        }

        let peoplePerGroup = totalPeople / 2

        let cluster1Center = CGPoint(
            x: size.width * 0.75,
            y: size.height * 0.25
        )

        let cluster2Center = CGPoint(
            x: size.width * 0.25,
            y: size.height * 0.75
        )

        let existingCircles = circles
        let hasExistingCircles = !existingCircles.isEmpty

        let baseRadius: CGFloat = 90
        let minSpacing: CGFloat = 55

        circles = (0..<totalPeople).map { index in
            let clusterIndex = index / peoplePerGroup
            let clusterCenter = clusterIndex == 0 ? cluster1Center : cluster2Center
            let personIndexInCluster = index % peoplePerGroup

            let existingCircle = hasExistingCircles && index < existingCircles.count ? existingCircles[index] : nil
            let groupedMinSize: CGFloat = 55
            let groupedMaxSize: CGFloat = 120
            let randomSize = existingCircle?.size ?? CGFloat.random(in: groupedMinSize...groupedMaxSize)
            let imageName = existingCircle?.imageName ?? dummyImageNames[index]

            let layer = personIndexInCluster / 5
            let positionInLayer = personIndexInCluster % 5
            let layerRadius = baseRadius + CGFloat(layer) * minSpacing
            let remainingInLayer = min(5, peoplePerGroup - layer * 5)
            let angleStep = remainingInLayer > 1 ? (2.0 * .pi) / CGFloat(remainingInLayer) : 0
            let angle = Double(positionInLayer) * Double(angleStep) + Double.random(in: -0.15...0.15)

            let radiusVariation = CGFloat.random(in: 0.75...1.0)
            let offsetX = CGFloat.random(in: -15...15)
            let offsetY = CGFloat.random(in: -15...15)

            let targetX = clusterCenter.x + layerRadius * radiusVariation * CGFloat(cos(angle)) + offsetX
            let targetY = clusterCenter.y + layerRadius * radiusVariation * CGFloat(sin(angle)) + offsetY

            let startX = existingCircle?.position.x ?? targetX
            let startY = existingCircle?.position.y ?? targetY

            let finalPosition = hasExistingCircles ? CGPoint(x: startX, y: startY) : CGPoint(x: targetX, y: targetY)
            return AnimatedCircle(
                id: existingCircle?.id ?? UUID(),
                position: finalPosition,
                size: randomSize,
                opacity: 1.0,
                imageName: imageName,
                isVisible: true,
                scale: 1.0,
                targetPosition: CGPoint(x: targetX, y: targetY)
            )
        }

        savedGroupedPositions = circles.map { $0.targetPosition ?? $0.position }
    }

    private func transitionToMode(_ newMode: AnimationMode, in size: CGSize) {
        switch newMode {
        case .free:
            transitionToFreeMode(in: size)
        case .grouped:
            transitionToGroupedMode(in: size)
        case .exiting:
            transitionToExitingMode(in: size)
        }
    }

    private func transitionToFreeMode(in size: CGSize) {
        if !savedFreePositions.isEmpty && savedFreePositions.count == circles.count {
            for index in circles.indices {
                var circle = circles[index]
                circle.position = savedFreePositions[index]
                circle.opacity = 1.0
                circles[index] = circle
            }
        } else {
            let margin: CGFloat = 20
            let minX = margin
            let minY = margin
            let maxX = size.width - margin
            let maxY = size.height - margin

            var usedPositions: [CGPoint] = []
            let minDistance: CGFloat = 40

            for index in circles.indices {
                var circle = circles[index]

                var attempts = 0
                var position: CGPoint
                repeat {
                    position = CGPoint(
                        x: CGFloat.random(in: minX...maxX),
                        y: CGFloat.random(in: minY...maxY)
                    )
                    attempts += 1

                    if attempts > 20 {
                        break
                    }
                } while usedPositions.contains { existingPos in
                    let distance = sqrt(
                        pow(position.x - existingPos.x, 2) +
                        pow(position.y - existingPos.y, 2)
                    )
                    return distance < minDistance
                }

                usedPositions.append(position)
                circle.position = position
                circle.opacity = 1.0
                circles[index] = circle
            }

            savedFreePositions = circles.map { $0.position }
        }
    }

    private func transitionToGroupedMode(in size: CGSize) {
        if !savedGroupedPositions.isEmpty && savedGroupedPositions.count == circles.count {
            for index in circles.indices {
                var circle = circles[index]
                circle.position = savedGroupedPositions[index]
                circle.opacity = 1.0
                circles[index] = circle
            }
        } else {
            let peoplePerGroup = totalPeople / 2

            let cluster1Center = CGPoint(
                x: size.width * 0.75,
                y: size.height * 0.25
            )

            let cluster2Center = CGPoint(
                x: size.width * 0.25,
                y: size.height * 0.75
            )

            let baseRadius: CGFloat = 90
            let minSpacing: CGFloat = 55

            for index in circles.indices {
                var circle = circles[index]
                let clusterIndex = index / peoplePerGroup
                let clusterCenter = clusterIndex == 0 ? cluster1Center : cluster2Center
                let personIndexInCluster = index % peoplePerGroup

                let groupedMinSize: CGFloat = 55
                let groupedMaxSize: CGFloat = 120
                if circle.size < groupedMinSize {
                    circle.size = CGFloat.random(in: groupedMinSize...groupedMaxSize)
                } else if circle.size > groupedMaxSize {
                    circle.size = groupedMaxSize
                }

                let layer = personIndexInCluster / 5
                let positionInLayer = personIndexInCluster % 5
                let layerRadius = baseRadius + CGFloat(layer) * minSpacing
                let remainingInLayer = min(5, peoplePerGroup - layer * 5)
                let angleStep = remainingInLayer > 1 ? (2.0 * .pi) / CGFloat(remainingInLayer) : 0
                let angle = Double(positionInLayer) * Double(angleStep) + Double.random(in: -0.15...0.15)

                let radiusVariation = CGFloat.random(in: 0.75...1.0)
                let offsetX = CGFloat.random(in: -15...15)
                let offsetY = CGFloat.random(in: -15...15)

                let targetX = clusterCenter.x + layerRadius * radiusVariation * CGFloat(cos(angle)) + offsetX
                let targetY = clusterCenter.y + layerRadius * radiusVariation * CGFloat(sin(angle)) + offsetY

                circle.position = CGPoint(x: targetX, y: targetY)
                circle.targetPosition = CGPoint(x: targetX, y: targetY)
                circle.opacity = 1.0
                circles[index] = circle
            }

            savedGroupedPositions = circles.map { $0.position }
        }
    }

    private func initializeExitingMode(in size: CGSize) {
        if circles.isEmpty {
            initializeGroupedMode(in: size)
            transitionToExitingMode(in: size)
        } else {
            transitionToExitingMode(in: size)
        }
    }

    private func transitionToExitingMode(in size: CGSize) {
        let offset: CGFloat = 300

        for index in circles.indices {
            var circle = circles[index]

            let currentX = circle.position.x
            let currentY = circle.position.y

            let toLeft = currentX
            let toRight = size.width - currentX
            let toTop = currentY
            let toBottom = size.height - currentY

            let minDistance = min(toLeft, toRight, toTop, toBottom)

            var exitX = currentX
            var exitY = currentY

            if minDistance == toLeft {
                exitX = -offset
            } else if minDistance == toRight {
                exitX = size.width + offset
            } else if minDistance == toTop {
                exitY = -offset
            } else {
                exitY = size.height + offset
            }

            circle.position = CGPoint(x: exitX, y: exitY)
            circle.opacity = 0.0

            circles[index] = circle
        }
    }

    private func adjustCirclesToNewSize(_ newSize: CGSize) {
        let margin = maxSize / 2
        for index in circles.indices {
            var circle = circles[index]
            circle.position.x = max(margin, min(newSize.width - margin, circle.position.x))
            circle.position.y = max(margin, min(newSize.height - margin, circle.position.y))
            circles[index] = circle
        }
    }
}

struct AnimatedCircle: Identifiable {
    let id: UUID
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var imageName: String
    var isVisible: Bool
    var scale: CGFloat
    var targetPosition: CGPoint?
}

struct PersonCircleView: View {
    let imageName: String
    let size: CGFloat
    let scale: CGFloat
    let isGrouped: Bool

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        Color.white.opacity(isGrouped ? 0.5 : 0.3),
                        lineWidth: isGrouped ? 2.5 : 1.5
                    )
            )
            .shadow(
                color: Color.black.opacity(isGrouped ? 0.2 : 0.1),
                radius: isGrouped ? 4 : 2,
                x: 0,
                y: isGrouped ? 2 : 1
            )
            .scaleEffect(scale)
    }
}
