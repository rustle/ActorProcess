//
//  Run.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import ActorProcess

public protocol ExportedObject {
    init(identifier: String, connection: AgentConnection)
}

@objc
public class Run : NSObject {
    private func identifier() -> String {
        let arguments = ProcessInfo.processInfo.arguments
        guard var index = arguments.firstIndex(where: { return $0 == "--identifier" }) else {
            exit(1)
        }
        index += 1
        guard index < arguments.count else {
            exit(1)
        }
        return arguments[index]
    }
    private var actor: ActorProcess?
    @objc
    public func publish(exportedInterfaceProtocol: Protocol,
                        exportedObjectClass: NSObject.Type) {
        run(exportedInterfaceProtocol: exportedInterfaceProtocol,
            exportedObjectClass: exportedObjectClass,
            connectionExchangeType: .publish)
    }
    @objc
    public func handshake(exportedInterfaceProtocol: Protocol,
                          exportedObjectClass: NSObject.Type) {
        run(exportedInterfaceProtocol: exportedInterfaceProtocol,
            exportedObjectClass: exportedObjectClass,
            connectionExchangeType: .handshake)
    }
    private func run(exportedInterfaceProtocol: Protocol,
                     exportedObjectClass: NSObject.Type,
                     connectionExchangeType: ActorProcess.ConnectionExchangeType) {
        let identifier = self.identifier()
        let connection = AgentConnection(identifier: "example")
        let actor = ActorProcess(identifier: identifier, agentConnection: connection, connectionExchangeType: connectionExchangeType)
        actor.exportedInterfaceProtocol = exportedInterfaceProtocol
        let ExportedObjectType = exportedObjectClass as! ExportedObject.Type
        actor.exportedObject = ExportedObjectType.init(identifier: identifier, connection: actor.connection)
        actor.resume()
        self.actor = actor
        CFRunLoopRun()
    }
}
