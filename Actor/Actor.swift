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
    @objc public var connection: Any {
        return agentConnection
    }
    @objc public init(identifier: String, agentIdentifier: String) {
        self.identifier = identifier
        agentConnection = AgentConnection(identifier: agentIdentifier)
        listener = NSXPCListener.anonymous()
        super.init()
        listener.delegate = self
    }
    @objc public func resume() {
        listener.resume()
        agentConnection.resume()
        agentConnection.proxy?.handshake(endpoint: listener.endpoint, identifier: identifier) { _ in
            
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
