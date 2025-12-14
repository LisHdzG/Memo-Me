//
//  NetworkMonitor.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 14/12/25.
//

import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        startMonitoring()
    }
    
    nonisolated func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let status = path.status == .satisfied
            let connectionType = Self.getConnectionType(path: path)
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isConnected = status
                self.connectionType = connectionType
            }
        }
        monitor.start(queue: queue)
    }
    
    nonisolated func stopMonitoring() {
        monitor.cancel()
    }
    
    nonisolated private static func getConnectionType(path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    nonisolated func isConnectedSync() -> Bool {
        return monitor.currentPath.status == .satisfied
    }
}
