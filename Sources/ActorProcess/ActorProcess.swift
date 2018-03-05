//
//  ActorProcess.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation

public class ActorProcess {
    private class Delegate : NSObject, NSXPCListenerDelegate {
        var exportedInterfaceProtocol: Protocol?
        public var exportedObject: Any?
        var acceptConnection: ((NSXPCConnection) -> Void)?
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
            acceptConnection?(newConnection)
            newConnection.exportedInterface = NSXPCInterface(with: exportedInterfaceProtocol)
            newConnection.exportedObject = exportedObject
            newConnection.resume()
            return true
        }
    }
    private let delegate = Delegate()
    @objc public var exportedInterfaceProtocol: Protocol? {
        get {
            return delegate.exportedInterfaceProtocol
        }
        set {
            delegate.exportedInterfaceProtocol = newValue
        }
    }
    @objc public var exportedObject: Any? {
        get {
            return delegate.exportedObject
        }
        set {
            delegate.exportedObject = newValue
        }
    }
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
    public init(identifier: String,
                agentConnection: AgentConnection,
                connectionExchangeType: ConnectionExchangeType = .handshake) {
        self.identifier = identifier
        self.agentConnection = agentConnection
        self.connectionExchangeType = connectionExchangeType
        listener = NSXPCListener.anonymous()
        listener.delegate = delegate
        delegate.acceptConnection = { [weak self] connection in
            self?.xpcConnection = connection
        }
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
}
