//
//  ActorConnection.swift
//
//  Copyright © 2018-2019 Doug Russell. All rights reserved.
//

import Foundation
import Combine

public class ActorConnection<ProxyType>: ObservableObject {
    public let identifier: String
    public private(set) var configuration: Configuration<ProxyType>
    public var proxy: ProxyType? {
        return configuration.proxy
    }
    public var processIdentifier: Int {
        return Int(process.processIdentifier)
    }
    public var xpcConnection: NSXPCConnection? {
        return configuration.xpcConnection
    }
    public enum Exit {
        case expected
        case unexpected
    }
    public enum State {
        case new
        case running
        case connected
        case exited(Exit)
    }
    @Published public private(set) var state = State.new
    private let process: Process
    private var monitor: ProcessMonitor?
    private var launchTime: CFAbsoluteTime?
    private var exitTime: CFAbsoluteTime?
    private let agentConnection: AgentConnection
    public init(identifier: String = UUID().uuidString,
                configuration: Configuration<ProxyType>,
                agentConnection: AgentConnection) {
        self.identifier = identifier
        self.configuration = configuration
        self.agentConnection = agentConnection
        process = Process()
    }
    public func launch(connectionExchangeType: ActorProcess.ConnectionExchangeType = .handshake) {
        switch state {
        case .new:
            break
        default:
            return
        }
        launchTime = CFAbsoluteTimeGetCurrent()
        guard let bundle = try? configuration.xpcBundle() else {
            return
        }
        process.launchPath = bundle.executablePath
        process.environment = [
            "DYLD_FRAMEWORK_PATH" : bundle.privateFrameworksPath!
        ]
        process.arguments = [
            "--identifier",
            identifier
        ]
        process.launch()
        monitor = ProcessMonitor(process: process)
        monitor?.didExit = { [weak self] monitor in
            self?.didExit()
        }
        monitor?.schedule()
        switch connectionExchangeType {
        case .handshake:
            agentConnection.proxy?.handshake(endpoint: nil, identifier: identifier) { [weak self] endpoint in
                self?.receive(endpoint: endpoint)
            }
        case .publish:
            agentConnection.proxy?.publishedEndpoint(identifier: identifier) { [weak self] endpoint in
                self?.receive(endpoint: endpoint)
            }
        }
        state = .running
    }
    private func didExit() {
        self.exitTime = CFAbsoluteTimeGetCurrent()
        switch state {
        case .exited(let exit):
            switch exit {
            case .expected:
                break
            default:
                self.state = .exited(.unexpected)
            }
        default:
            self.state = .exited(.unexpected)
        }
        monitor?.unschedule()
        monitor = nil
    }
    public func terminate() {
        process.terminate()
        state = .exited(.expected)
    }
    private func receive(endpoint: NSXPCListenerEndpoint?) {
        guard let endpoint = endpoint else {
            return
        }
        DispatchQueue.main.async {
            self._receive(endpoint: endpoint)
        }
    }
    private func _receive(endpoint: NSXPCListenerEndpoint) {
        let connection = NSXPCConnection(listenerEndpoint: endpoint)
        connection.remoteObjectInterface = configuration.interface
        connection.resume()
        configuration.receive(xpcConnection: connection)
        state = .connected
    }
}

extension ActorConnection : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Actor<\(ProxyType.self)> \(process.processIdentifier) \(identifier)"
    }
}

public extension ActorConnection {
    struct Configuration<ProxyType> {
        public var interface: NSXPCInterface {
            return impl.interface
        }
        public var xpcConnection: NSXPCConnection? {
            return impl.xpcConnection
        }
        public func xpcBundle() throws -> Bundle {
            return try impl.xpcBundle()
        }
        public var proxy: ProxyType? {
            return impl.proxy as? ProxyType
        }
        public mutating func receive(xpcConnection: NSXPCConnection) {
            impl.receive(xpcConnection: xpcConnection)
        }
        private var impl: ActorConnectionConfigurationImpl
        public init(impl: ActorConnectionConfigurationImpl) {
            self.impl = impl
        }
    }
}

public protocol ActorConnectionConfigurationImpl {
    var interface: NSXPCInterface { get }
    var xpcConnection: NSXPCConnection? { get }
    func xpcBundle() throws -> Bundle
    var proxy: Any? { get }
    mutating func receive(xpcConnection: NSXPCConnection)
}
