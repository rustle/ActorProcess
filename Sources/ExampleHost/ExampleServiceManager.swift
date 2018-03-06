//
//  ExampleServiceManager.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import ActorProcess
import Signals

class ExampleServiceManager {
    let agentConnection: AgentConnection
    init(identifier: String) {
        do {
            try AgentConnection.load(identifier: identifier)
        } catch let error {
            print(error)
        }
        agentConnection = AgentConnection(identifier: identifier)
        agentConnection.resume()
    }
    private var services = [Int : Service<ExampleMessaging>]()
    func connect(identifier: Int) -> Service<ExampleMessaging> {
        if let service = services[identifier] {
            return service
        }
        let connection = ActorConnection(configuration: ExampleConfigImpl.config(identifier: identifier), agentConnection: agentConnection)
        connection.stateSignal.subscribe(with: connection) { [weak self] state in
            switch state {
            case .new:
                break
            case .running:
                break
            case .connected:
                break
            case .exited(let exit):
                switch exit {
                case .unexpected:
                    self?.unexpectedExit(identifier: identifier)
                case .expected:
                    self?.expectedExit(identifier: identifier)
                }
            }
        }
        connection.launch()
        let service = Service(connection: connection, identifier: identifier)
        services[identifier] = service
        return service
    }
    private var candidatesForRelaunch = [Int]()
    private func unexpectedExit(identifier: Int) {
        candidatesForRelaunch.append(identifier)
        services.removeValue(forKey: identifier)
    }
    private func expectedExit(identifier: Int) {
        services.removeValue(forKey: identifier)
    }
    func disconnect(identifier: Int) {
        guard let service = services.removeValue(forKey: identifier) else {
            return
        }
        service.connection.terminate()
    }
}

public class Service<ProxyType> {
    public var connection: ActorConnection<ProxyType>
    public let identifier: Int
    init(connection: ActorConnection<ProxyType>, identifier: Int) {
        self.connection = connection
        self.identifier = identifier
    }
}
