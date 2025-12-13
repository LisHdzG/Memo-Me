//
//  ContactSphereView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI
import SceneKit

struct ContactSphereView: UIViewRepresentable {
    let contacts: [Contact]
    @Binding var rotationSpeed: Double
    @Binding var isAutoRotating: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear
        sceneView.antialiasingMode = .multisampling4X
        
        // Configurar gestos
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        sceneView.addGestureRecognizer(panGesture)
        
        context.coordinator.sceneView = sceneView
        context.coordinator.contacts = contacts
        context.coordinator.rotationSpeed = rotationSpeed
        context.coordinator.isAutoRotating = isAutoRotating
        
        // Crear escena inicial
        context.coordinator.createScene()
        context.coordinator.startAutoRotation()
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Verificar si los contactos cambiaron o si la escena no existe
        let contactsChanged = context.coordinator.contacts.count != contacts.count
        let sceneNeedsUpdate = uiView.scene == nil || contactsChanged
        
        if sceneNeedsUpdate {
            context.coordinator.contacts = contacts
            context.coordinator.createScene()
        }
        
        // Actualizar velocidad de rotación
        context.coordinator.rotationSpeed = rotationSpeed
        context.coordinator.isAutoRotating = isAutoRotating
        
        if isAutoRotating {
            context.coordinator.startAutoRotation()
        } else {
            context.coordinator.stopAutoRotation()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(contacts: contacts, rotationSpeed: rotationSpeed, isAutoRotating: isAutoRotating)
    }
    
    
    
    class Coordinator: NSObject {
        var sceneView: SCNView?
        var contacts: [Contact]
        var rotationSpeed: Double
        var isAutoRotating: Bool
        var rotationAction: SCNAction?
        var lastPanLocation: CGPoint = .zero
        var isUserInteracting: Bool = false
        var contactsContainer: SCNNode?
        
        init(contacts: [Contact], rotationSpeed: Double, isAutoRotating: Bool) {
            self.contacts = contacts
            self.rotationSpeed = rotationSpeed
            self.isAutoRotating = isAutoRotating
        }
        
        func createScene() {
            guard let sceneView = sceneView else { return }
            
            let scene = SCNScene()
            
            // Crear nodo contenedor para todos los contactos (para rotación)
            let contactsContainer = SCNNode()
            contactsContainer.name = "contactsContainer"
            scene.rootNode.addChildNode(contactsContainer)
            self.contactsContainer = contactsContainer
            
            // Distribuir contactos en un cilindro (solo laterales, no arriba ni abajo)
            let contactCount = contacts.count
            guard contactCount > 0 else {
                sceneView.scene = scene
                return
            }
            
            // Radio del cilindro (muy aumentado para que salga de los bordes de la vista)
            let cylinderRadius: Float = 4.0
            
            // Altura del cilindro (aumentada)
            let cylinderHeight: Float = 5.0
            let minY: Float = -cylinderHeight / 2
            let maxY: Float = cylinderHeight / 2
            
            // Almacenar posiciones para evitar traslapes
            var usedPositions: [(x: Float, y: Float, z: Float)] = []
            let minDistance: Float = 0.85 // Distancia mínima reducida para que estén más cerca
            
            // Distribuir imágenes alrededor del cilindro
            for (index, contact) in contacts.enumerated() {
                // Distribución uniforme del ángulo alrededor del cilindro
                let angleStep = (2.0 * Double.pi) / Double(contactCount)
                let theta = angleStep * Double(index)
                
                // Altura aleatoria distribuida a lo largo del cilindro
                // Usar múltiples funciones trigonométricas con diferentes frecuencias para crear distribución variada
                let randomSeed1 = sin(Double(index) * 0.618033988749895) // Golden ratio
                let randomSeed2 = cos(Double(index) * 1.414213562373095) // √2
                let randomSeed3 = sin(Double(index) * 2.718281828459045) // e
                let combinedRandom = (randomSeed1 + randomSeed2 + randomSeed3) / 3.0 // Promedio
                let normalizedRandom = (combinedRandom + 1.0) / 2.0 // Normalizar a 0-1
                var y = Float(minY + (maxY - minY) * Float(normalizedRandom))
                
                // Posición en el perímetro del cilindro
                var x = Float(cos(theta)) * cylinderRadius
                var z = Float(sin(theta)) * cylinderRadius
                
                // Verificar y ajustar posición para evitar traslapes
                var attempts = 0
                var adjustmentDirection: Float = 1.0
                while attempts < 20 {
                    var tooClose = false
                    var closestDistance: Float = Float.greatestFiniteMagnitude
                    
                    for usedPos in usedPositions {
                        let distance = sqrt(pow(x - usedPos.x, 2) + pow(y - usedPos.y, 2) + pow(z - usedPos.z, 2))
                        if distance < minDistance {
                            tooClose = true
                            closestDistance = min(closestDistance, distance)
                        }
                    }
                    
                    if !tooClose {
                        break
                    }
                    
                    // Ajustar altura con incremento más grande y alternando dirección
                    let adjustment = minDistance - closestDistance + 0.2
                    y = max(minY, min(maxY, y + adjustment * adjustmentDirection))
                    adjustmentDirection *= -1.0 // Alternar dirección
                    
                    attempts += 1
                }
                
                // Guardar posición usada
                usedPositions.append((x: x, y: y, z: z))
                
                // Crear nodo para la imagen
                let imageNode = createImageNode(for: contact, index: index)
                imageNode.position = SCNVector3(x, y, z)
                
                // Hacer que la imagen mire hacia afuera del cilindro (hacia la cámara)
                // Calcular dirección hacia afuera desde el centro del cilindro
                let outwardDirection = SCNVector3(x, 0, z)
                let targetPosition = SCNVector3(
                    imageNode.position.x + outwardDirection.x,
                    imageNode.position.y,
                    imageNode.position.z + outwardDirection.z
                )
                imageNode.look(at: targetPosition, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, 1))
                
                // Agregar animación de pulso sutil con variación aleatoria
                let randomDelay = Double.random(in: 0...2)
                let randomDuration = 2.0 + Double.random(in: 0...1.5)
                let pulseAction = SCNAction.sequence([
                    SCNAction.wait(duration: randomDelay),
                    SCNAction.scale(to: 1.15, duration: randomDuration),
                    SCNAction.scale(to: 0.9, duration: randomDuration)
                ])
                let repeatPulse = SCNAction.repeatForever(pulseAction)
                imageNode.runAction(repeatPulse)
                
                contactsContainer.addChildNode(imageNode)
            }
            
            // Configurar cámara - ajustada para que las imágenes salgan de los bordes
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.fieldOfView = 75  // Campo de visión más estrecho para que salgan de los bordes
            cameraNode.position = SCNVector3(0, 0, 7)  // Posición para que los laterales se salgan
            cameraNode.look(at: SCNVector3(0, 0, 0), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, 1))
            scene.rootNode.addChildNode(cameraNode)
            
            // Configurar iluminación
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light?.type = .omni
            lightNode.light?.intensity = 1000
            lightNode.position = SCNVector3(5, 5, 5)
            scene.rootNode.addChildNode(lightNode)
            
            let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light?.type = .ambient
            ambientLightNode.light?.color = UIColor.white.withAlphaComponent(0.7)
            scene.rootNode.addChildNode(ambientLightNode)
            
            sceneView.scene = scene
        }
        
        private func createImageNode(for contact: Contact, index: Int) -> SCNNode {
            // Solo dos tamaños: grandes y medianas
            let sizeVariation = [1.3, 1.0] // Grandes y medianas
            let baseSize: CGFloat = 0.6
            let sizeMultiplier = sizeVariation[index % sizeVariation.count]
            let finalSize = baseSize * sizeMultiplier
            
            // Crear imagen circular recortada
            let circularImage = createCircularImage(from: contact.imageName, size: CGSize(width: 200, height: 200))
            
            // Crear plano para la imagen
            let plane = SCNPlane(width: finalSize, height: finalSize)
            plane.firstMaterial?.diffuse.contents = circularImage
            plane.firstMaterial?.isDoubleSided = true
            plane.firstMaterial?.lightingModel = .constant
            
            let imageNode = SCNNode(geometry: plane)
            
            // Crear borde circular sutil
            let borderGeometry = SCNTorus(ringRadius: finalSize * 0.52, pipeRadius: 0.008)
            borderGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.4)
            borderGeometry.firstMaterial?.lightingModel = .constant
            let borderNode = SCNNode(geometry: borderGeometry)
            borderNode.rotation = SCNVector4(1, 0, 0, Double.pi / 2)
            imageNode.addChildNode(borderNode)
            
            return imageNode
        }
        
        private func createCircularImage(from imageName: String, size: CGSize) -> UIImage? {
            // Intentar cargar la imagen
            guard let image = UIImage(named: imageName) else {
                // Debug: imprimir si no se encuentra la imagen
                print("⚠️ No se pudo cargar la imagen: \(imageName)")
                // Crear imagen de fallback circular
                return createFallbackCircularImage(size: size)
            }
            
            print("✅ Imagen cargada: \(imageName)")
            
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                
                // Crear path circular
                let path = UIBezierPath(ovalIn: rect)
                path.addClip()
                
                // Calcular aspect fill para que la imagen cubra todo el círculo (se puede cortar)
                let imageSize = image.size
                let imageAspect = imageSize.width / imageSize.height
                let rectAspect = rect.width / rect.height
                
                var drawRect = rect
                
                if imageAspect > rectAspect {
                    // La imagen es más ancha, ajustar ancho para cubrir toda la altura
                    let scaledWidth = rect.height * imageAspect
                    drawRect = CGRect(
                        x: (rect.width - scaledWidth) / 2,
                        y: 0,
                        width: scaledWidth,
                        height: rect.height
                    )
                } else {
                    // La imagen es más alta, ajustar altura para cubrir todo el ancho
                    let scaledHeight = rect.width / imageAspect
                    drawRect = CGRect(
                        x: 0,
                        y: (rect.height - scaledHeight) / 2,
                        width: rect.width,
                        height: scaledHeight
                    )
                }
                
                // Dibujar imagen con aspect fill (cubre todo, se puede cortar)
                image.draw(in: drawRect)
                
                // Agregar borde sutil
                UIColor.white.withAlphaComponent(0.3).setStroke()
                path.lineWidth = 2
                path.stroke()
            }
        }
        
        private func createFallbackCircularImage(size: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(ovalIn: rect)
                
                // Color de fondo
                UIColor.systemPurple.setFill()
                path.fill()
                
                // Borde
                UIColor.white.withAlphaComponent(0.3).setStroke()
                path.lineWidth = 2
                path.stroke()
            }
        }
        
        func startAutoRotation() {
            guard isAutoRotating, !isUserInteracting,
                  let scene = sceneView?.scene,
                  let container = scene.rootNode.childNode(withName: "contactsContainer", recursively: false) else {
                return
            }
            
            contactsContainer = container
            
            // Detener rotación anterior si existe
            container.removeAction(forKey: "autoRotation")
            
            // Crear rotación continua suave alrededor del eje Y
            let rotationAction = SCNAction.rotateBy(x: 0, y: CGFloat(rotationSpeed * 0.1), z: 0, duration: 1.0)
            let repeatRotation = SCNAction.repeatForever(rotationAction)
            
            container.runAction(repeatRotation, forKey: "autoRotation")
            self.rotationAction = repeatRotation
        }
        
        func stopAutoRotation() {
            contactsContainer?.removeAction(forKey: "autoRotation")
            rotationAction = nil
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let sceneView = sceneView,
                  let scene = sceneView.scene,
                  let container = scene.rootNode.childNode(withName: "contactsContainer", recursively: false) else {
                return
            }
            
            let location = gesture.location(in: sceneView)
            
            switch gesture.state {
            case .began:
                lastPanLocation = location
                isUserInteracting = true
                // Pausar rotación automática
                stopAutoRotation()
                
            case .changed:
                let deltaX = location.x - lastPanLocation.x
                
                // Solo rotación horizontal (eje Y) - no permitir rotación vertical
                let rotationY = Float(deltaX) * 0.01
                
                // Aplicar rotación solo en el eje Y (horizontal)
                let currentEuler = container.eulerAngles
                container.eulerAngles = SCNVector3(
                    currentEuler.x,  // Mantener X sin cambios (no rotación vertical)
                    currentEuler.y + rotationY,  // Solo rotar horizontalmente
                    currentEuler.z
                )
                
                lastPanLocation = location
                
            case .ended, .cancelled:
                isUserInteracting = false
                // Reanudar rotación automática después de un breve delay
                if isAutoRotating {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if !self.isUserInteracting {
                            self.startAutoRotation()
                        }
                    }
                }
                
            default:
                break
            }
        }
    }
}

