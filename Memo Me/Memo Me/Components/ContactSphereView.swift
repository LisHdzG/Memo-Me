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
    let spaceId: String?
    @Binding var rotationSpeed: Double
    @Binding var isAutoRotating: Bool
    var onContactTapped: ((Contact) -> Void)?
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = .clear
        sceneView.antialiasingMode = .multisampling4X
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        sceneView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        panGesture.require(toFail: tapGesture)
        
        context.coordinator.sceneView = sceneView
        context.coordinator.contacts = contacts
        context.coordinator.spaceId = spaceId
        context.coordinator.rotationSpeed = rotationSpeed
        context.coordinator.isAutoRotating = isAutoRotating
        context.coordinator.onContactTapped = onContactTapped
        
        print("DEBUG makeUIView: Callback configurado: \(onContactTapped != nil)")
        
        context.coordinator.createScene()
        context.coordinator.startAutoRotation()
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        let contactsChanged = context.coordinator.contacts.count != contacts.count
        let sceneNeedsUpdate = uiView.scene == nil || contactsChanged
        
        // Si cambió el spaceId, recrear la escena para actualizar los corazones
        let spaceIdChanged = context.coordinator.spaceId != spaceId
        if sceneNeedsUpdate || spaceIdChanged {
            context.coordinator.contacts = contacts
            context.coordinator.createScene()
        }
        
        context.coordinator.rotationSpeed = rotationSpeed
        context.coordinator.isAutoRotating = isAutoRotating
        context.coordinator.spaceId = spaceId
        // Siempre actualizar el callback
        context.coordinator.onContactTapped = onContactTapped
        
        print("DEBUG updateUIView: Callback actualizado: \(onContactTapped != nil), sceneExists: \(uiView.scene != nil)")
        
        // Actualizar el mapeo solo si la escena ya existe (no durante la creación)
        if uiView.scene != nil && !sceneNeedsUpdate {
            context.coordinator.updateNodeMapping()
            print("DEBUG updateUIView: Mapeo actualizado, tiene \(context.coordinator.nodeToContactMap.count) entradas")
        }
        
        if isAutoRotating {
            context.coordinator.startAutoRotation()
        } else {
            context.coordinator.stopAutoRotation()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(contacts: contacts, spaceId: spaceId, rotationSpeed: rotationSpeed, isAutoRotating: isAutoRotating, onContactTapped: onContactTapped)
    }
    
    class Coordinator: NSObject {
        var sceneView: SCNView?
        var contacts: [Contact]
        var spaceId: String?
        var rotationSpeed: Double
        var isAutoRotating: Bool
        var rotationAction: SCNAction?
        var lastPanLocation: CGPoint = .zero
        var isUserInteracting: Bool = false
        var contactsContainer: SCNNode?
        var loadedImages: [String: UIImage] = [:]
        var nodeToContactMap: [SCNNode: Contact] = [:]
        var onContactTapped: ((Contact) -> Void)?
        private let favoriteService = FavoriteService.shared
        
        init(contacts: [Contact], spaceId: String?, rotationSpeed: Double, isAutoRotating: Bool, onContactTapped: ((Contact) -> Void)? = nil) {
            self.contacts = contacts
            self.spaceId = spaceId
            self.rotationSpeed = rotationSpeed
            self.isAutoRotating = isAutoRotating
            self.onContactTapped = onContactTapped
        }
        
        func updateNodeMapping() {
            guard let container = contactsContainer else { return }
            nodeToContactMap.removeAll()
            
            // Reconstruir el mapa basándose en los nombres de los nodos
            for contact in contacts {
                let contactId = contact.id.uuidString
                // Buscar el nodo por su nombre
                if let node = container.childNode(withName: "contact_\(contactId)", recursively: false) {
                    nodeToContactMap[node] = contact
                }
            }
        }
        
        func findContactNode(byId contactId: UUID, in container: SCNNode) -> SCNNode? {
            return container.childNode(withName: "contact_\(contactId.uuidString)", recursively: false)
        }
        
        func getContact(for node: SCNNode) -> Contact? {
            print("DEBUG getContact: buscando para nodo name=\(node.name ?? "nil"), mapa tiene \(nodeToContactMap.count) entradas")
            
            // Primero buscar directamente en el mapa
            if let contact = nodeToContactMap[node] {
                print("DEBUG getContact: encontrado directamente en mapa")
                return contact
            }
            
            // Si no está directamente, buscar en el parent y por nombre
            var currentNode: SCNNode? = node
            var depth = 0
            while let current = currentNode, depth < 5 {
                // Buscar en el mapa
                if let contact = nodeToContactMap[current] {
                    print("DEBUG getContact: encontrado en parent (depth=\(depth))")
                    return contact
                }
                
                // Buscar por nombre si tiene
                if let name = current.name, name.hasPrefix("contact_") {
                    let contactIdString = String(name.dropFirst("contact_".count))
                    print("DEBUG getContact: buscando por nombre, contactId=\(contactIdString)")
                    if let contactId = UUID(uuidString: contactIdString) {
                        // Buscar en el array de contactos
                        if let contact = contacts.first(where: { $0.id == contactId }) {
                            print("DEBUG getContact: encontrado por nombre en contacts array")
                            // Actualizar el mapa para futuras búsquedas
                            nodeToContactMap[current] = contact
                            return contact
                        }
                    }
                }
                
                currentNode = current.parent
                depth += 1
            }
            
            print("DEBUG getContact: NO encontrado después de buscar en depth=\(depth)")
            return nil
        }
        
        func createScene() {
            guard let sceneView = sceneView else { return }
            
            Task {
                await preloadImages()
                await MainActor.run {
                    self.createSceneWithLoadedImages()
                }
            }
        }
        
        private func createSceneWithLoadedImages() {
            guard let sceneView = sceneView else { return }
            
            // Limpiar el mapa de nodos antes de crear nueva escena
            nodeToContactMap.removeAll()
            
            let scene = SCNScene()
            
            let contactsContainer = SCNNode()
            contactsContainer.name = "contactsContainer"
            scene.rootNode.addChildNode(contactsContainer)
            self.contactsContainer = contactsContainer
            
            let contactCount = contacts.count
            guard contactCount > 0 else {
                sceneView.scene = scene
                return
            }
            
            let cylinderRadius: Float = 4.0
            let cylinderHeight: Float = 5.0
            let minY: Float = -cylinderHeight / 2
            let maxY: Float = cylinderHeight / 2
            
            var usedPositions: [(x: Float, y: Float, z: Float)] = []
            let minDistance: Float = 0.85
            
            for (index, contact) in contacts.enumerated() {
                let angleStep = (2.0 * Double.pi) / Double(contactCount)
                let theta = angleStep * Double(index)
                
                let randomSeed1 = sin(Double(index) * 0.618033988749895)
                let randomSeed2 = cos(Double(index) * 1.414213562373095)
                let randomSeed3 = sin(Double(index) * 2.718281828459045)
                let combinedRandom = (randomSeed1 + randomSeed2 + randomSeed3) / 3.0
                let normalizedRandom = (combinedRandom + 1.0) / 2.0
                var y = Float(minY + (maxY - minY) * Float(normalizedRandom))
                
                let x = Float(cos(theta)) * cylinderRadius
                let z = Float(sin(theta)) * cylinderRadius
                
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
                    
                    let adjustment = minDistance - closestDistance + 0.2
                    y = max(minY, min(maxY, y + adjustment * adjustmentDirection))
                    adjustmentDirection *= -1.0
                    
                    attempts += 1
                }
                
                usedPositions.append((x: x, y: y, z: z))
                
                // Calcular el tamaño del nodo (necesario para el corazón)
                let sizeVariation = [1.3, 1.0]
                let baseSize: CGFloat = 0.6
                let sizeMultiplier = sizeVariation[index % sizeVariation.count]
                let finalSize = baseSize * sizeMultiplier
                
                let imageNode = createImageNode(for: contact, index: index)
                imageNode.position = SCNVector3(x, y, z)
                
                // Asignar un nombre único al nodo basado en el ID del contacto
                imageNode.name = "contact_\(contact.id.uuidString)"
                
                // Mapear el nodo al contacto para detección de toques
                nodeToContactMap[imageNode] = contact
                
                let outwardDirection = SCNVector3(x, 0, z)
                let targetPosition = SCNVector3(
                    imageNode.position.x + outwardDirection.x,
                    imageNode.position.y,
                    imageNode.position.z + outwardDirection.z
                )
                imageNode.look(at: targetPosition, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, 1))
                
                let randomDelay = Double.random(in: 0...2)
                let randomDuration = 2.0 + Double.random(in: 0...1.5)
                let pulseAction = SCNAction.sequence([
                    SCNAction.wait(duration: randomDelay),
                    SCNAction.scale(to: 1.15, duration: randomDuration),
                    SCNAction.scale(to: 0.9, duration: randomDuration)
                ])
                let repeatPulse = SCNAction.repeatForever(pulseAction)
                imageNode.runAction(repeatPulse)
                
                // Agregar corazón si es favorito
                if isFavorite(contact: contact) {
                    let heartNode = createHeartNode(size: finalSize)
                    heartNode.position = SCNVector3(0, finalSize * 0.7, 0) // Encima del contacto
                    imageNode.addChildNode(heartNode)
                }
                
                contactsContainer.addChildNode(imageNode)
            }
            
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.fieldOfView = 75
            cameraNode.position = SCNVector3(0, 0, 7)
            cameraNode.look(at: SCNVector3(0, 0, 0), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, 1))
            scene.rootNode.addChildNode(cameraNode)
            
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
            // El mapeo ya se hizo cuando se agregaron los nodos, pero lo actualizamos por si acaso
            updateNodeMapping()
            
            print("DEBUG: Escena creada con \(contacts.count) contactos, mapa tiene \(nodeToContactMap.count) entradas")
            // Verificar que todos los contactos estén mapeados
            if nodeToContactMap.count != contacts.count {
                print("DEBUG WARNING: El mapa tiene \(nodeToContactMap.count) entradas pero hay \(contacts.count) contactos")
            }
        }
        
        private func createImageNode(for contact: Contact, index: Int) -> SCNNode {
            let sizeVariation = [1.3, 1.0]
            let baseSize: CGFloat = 0.6
            let sizeMultiplier = sizeVariation[index % sizeVariation.count]
            let finalSize = baseSize * sizeMultiplier
            
            let circularImage = createCircularImage(
                imageName: contact.imageName,
                imageUrl: contact.imageUrl,
                contactName: contact.name,
                size: CGSize(width: 200, height: 200)
            )
            
            let plane = SCNPlane(width: finalSize, height: finalSize)
            plane.firstMaterial?.diffuse.contents = circularImage
            plane.firstMaterial?.isDoubleSided = true
            plane.firstMaterial?.lightingModel = .constant
            
            let imageNode = SCNNode(geometry: plane)
            
            let borderGeometry = SCNTorus(ringRadius: finalSize * 0.52, pipeRadius: 0.008)
            borderGeometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.4)
            borderGeometry.firstMaterial?.lightingModel = .constant
            let borderNode = SCNNode(geometry: borderGeometry)
            borderNode.rotation = SCNVector4(1, 0, 0, Double.pi / 2)
            imageNode.addChildNode(borderNode)
            
            return imageNode
        }
        
        private func preloadImages() async {
            loadedImages.removeAll()
            let imageLoader = ImageLoaderService.shared
            
            for contact in contacts {
                let key = contact.imageUrl ?? contact.imageName ?? ""
                
                if loadedImages[key] != nil {
                    continue
                }
                
                var image: UIImage?
                
                // Intentar cargar desde URL usando el servicio
                if let imageUrl = contact.imageUrl {
                    image = await imageLoader.loadImage(from: imageUrl)
                }
                
                // Si no hay imagen desde URL, intentar desde assets locales
                if image == nil, let imageName = contact.imageName {
                    image = UIImage(named: imageName)
                }
                
                if let finalImage = image {
                    loadedImages[key] = finalImage
                }
            }
        }
        
        private func createCircularImage(imageName: String?, imageUrl: String?, contactName: String, size: CGSize) -> UIImage? {
            var image: UIImage?
            
            let key = imageUrl ?? imageName ?? ""
            if let cachedImage = loadedImages[key] {
                image = cachedImage
            } else if let imageName = imageName {
                image = UIImage(named: imageName)
            }
            
            guard let finalImage = image else {
                return createFallbackCircularImage(contactName: contactName, size: size)
            }
            
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(ovalIn: rect)
                path.addClip()
                
                let imageSize = finalImage.size
                let imageAspect = imageSize.width / imageSize.height
                let rectAspect = rect.width / rect.height
                
                var drawRect = rect
                
                if imageAspect > rectAspect {
                    let scaledWidth = rect.height * imageAspect
                    drawRect = CGRect(
                        x: (rect.width - scaledWidth) / 2,
                        y: 0,
                        width: scaledWidth,
                        height: rect.height
                    )
                } else {
                    let scaledHeight = rect.width / imageAspect
                    drawRect = CGRect(
                        x: 0,
                        y: (rect.height - scaledHeight) / 2,
                        width: rect.width,
                        height: scaledHeight
                    )
                }
                
                finalImage.draw(in: drawRect)
                
                UIColor.white.withAlphaComponent(0.3).setStroke()
                path.lineWidth = 2
                path.stroke()
            }
        }
        
        private func createFallbackCircularImage(contactName: String, size: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(ovalIn: rect)
                
                // Fondo con gradiente púrpura
                UIColor.systemPurple.setFill()
                path.fill()
                
                // Dibujar la inicial del nombre
                let initial = contactName.prefix(1).uppercased()
                let fontSize = size.width * 0.4
                let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.white
                ]
                
                let attributedString = NSAttributedString(string: initial, attributes: attributes)
                let stringSize = attributedString.size()
                let stringRect = CGRect(
                    x: (rect.width - stringSize.width) / 2,
                    y: (rect.height - stringSize.height) / 2,
                    width: stringSize.width,
                    height: stringSize.height
                )
                
                attributedString.draw(in: stringRect)
                
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
            container.removeAction(forKey: "autoRotation")
            
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
                stopAutoRotation()
                
            case .changed:
                let deltaX = location.x - lastPanLocation.x
                let rotationY = Float(deltaX) * 0.01
                
                let currentEuler = container.eulerAngles
                container.eulerAngles = SCNVector3(
                    currentEuler.x,
                    currentEuler.y + rotationY,
                    currentEuler.z
                )
                
                lastPanLocation = location
                
            case .ended, .cancelled:
                isUserInteracting = false
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
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = sceneView else {
                print("DEBUG: handleTap - sceneView es nil")
                return
            }
            
            let location = gesture.location(in: sceneView)
            
            // Usar hitTest sin opciones problemáticas, SceneKit manejará esto correctamente
            let hitResults = sceneView.hitTest(location, options: nil)
            
            print("DEBUG: handleTap - \(hitResults.count) hit results")
            
            // Buscar el nodo que fue tocado
            for result in hitResults {
                let node = result.node
                print("DEBUG: hit node name: \(node.name ?? "nil"), geometry: \(type(of: node.geometry))")
                
                // Intentar obtener el contacto usando nuestra función mejorada
                if let contact = getContact(for: node) {
                    print("DEBUG: Contacto encontrado: \(contact.name), llamando callback...")
                    if let callback = onContactTapped {
                        callback(contact)
                        print("DEBUG: Callback ejecutado")
                    } else {
                        print("DEBUG: ERROR - onContactTapped es nil")
                    }
                    return
                }
            }
            
            print("DEBUG: No se encontró contacto en el tap")
        }
        
        func isFavorite(contact: Contact) -> Bool {
            let contactId = contact.userId ?? contact.id.uuidString
            return favoriteService.isFavorite(contactId: contactId, for: spaceId)
        }
        
        func createHeartNode(size: CGFloat) -> SCNNode {
            // Crear un texto con emoji de corazón
            let heartSize: CGFloat = size * 0.3
            let heartText = "❤️"
            
            // Crear una imagen desde el texto del corazón
            let heartImage = createHeartImage(size: heartSize)
            let plane = SCNPlane(width: heartSize, height: heartSize)
            plane.firstMaterial?.diffuse.contents = heartImage
            plane.firstMaterial?.isDoubleSided = true
            plane.firstMaterial?.lightingModel = .constant
            
            let heartNode = SCNNode(geometry: plane)
            
            // Agregar una pequeña animación de pulso al corazón
            let pulseAction = SCNAction.sequence([
                SCNAction.scale(to: 1.2, duration: 0.5),
                SCNAction.scale(to: 1.0, duration: 0.5)
            ])
            let repeatPulse = SCNAction.repeatForever(pulseAction)
            heartNode.runAction(repeatPulse)
            
            return heartNode
        }
        
        func createHeartImage(size: CGFloat) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            return renderer.image { context in
                let font = UIFont.systemFont(ofSize: size * 0.8)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font
                ]
                let attributedString = NSAttributedString(string: "❤️", attributes: attributes)
                let stringSize = attributedString.size()
                let stringRect = CGRect(
                    x: (size - stringSize.width) / 2,
                    y: (size - stringSize.height) / 2,
                    width: stringSize.width,
                    height: stringSize.height
                )
                attributedString.draw(in: stringRect)
            }
        }
    }
}

