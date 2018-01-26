//
//  Actor.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation

public class Actor : NSObject, NSXPCListenerDelegate {
    @objc public var exportedInterfaceProtocol: Protocol?
    @objc public var exportedObject: Any?
    private let listener: NSXPCListener
    private var xpcConnection: NSXPCConnection?
    private let identifier: String
    private let agentConnection: AgentConnection
    public var connection: AgentConnection {
        return agentConnection
    }
    public enum ConnectionExchangeType {
        case handshake
        case publish
    }
    private let connectionExchangeType: ConnectionExchangeType
    public init(identifier: String, agentConnection: AgentConnection, connectionExchangeType: ConnectionExchangeType = .handshake) {
        self.identifier = identifier
        self.agentConnection = agentConnection
        self.connectionExchangeType = connectionExchangeType
        listener = NSXPCListener.anonymous()
        super.init()
        listener.delegate = self
    }
    public func resume() {
        listener.resume()
        agentConnection.resume()
        switch connectionExchangeType {
        case .handshake:
            agentConnection.proxy?.handshake(endpoint: listener.endpoint, identifier: identifier) { _ in
                
            }
        case .publish:
            agentConnection.proxy?.publish(endpoint: listener.endpoint, identifier: identifier)
        }
    }
    @objc public func listener(_ listener: NSXPCListener,
                               shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        do {
            var info = auditinfo_addr()
            guard getaudit_addr(&info, Int32(MemoryLayout<auditinfo_addr>.size)) == 0 else {
                return false
            }
            try newConnection.validate(teamIdentifier: "", auditSessionIdentifier: info.ai_asid)
        } catch {
            return false
        }
        guard let exportedInterfaceProtocol = exportedInterfaceProtocol, let exportedObject = exportedObject else {
            return false
        }
        xpcConnection = newConnection
        newConnection.exportedInterface = NSXPCInterface(with: exportedInterfaceProtocol)
        newConnection.exportedObject = exportedObject
        newConnection.resume()
        return true
    }
}
