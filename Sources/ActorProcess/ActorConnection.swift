//
//  ActorConnection.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import Signals

public class ActorConnection<ProxyType> {
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
    public private(set) var state = State.new {
        didSet {
            stateSignal=>state
        }
    }
    public var stateSignal = Signal<State>()
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
        process.launchPath = configuration.xpcBundle.executablePath
        process.environment = [
            "DYLD_FRAMEWORK_PATH" : configuration.xpcBundle.privateFrameworksPath!
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
    public struct Configuration<ProxyType> {
        public var interface: NSXPCInterface {
            return impl.interface
        }
        public var xpcConnection: NSXPCConnection? {
            return impl.xpcConnection
        }
        public var xpcBundle: Bundle {
            return impl.xpcBundle
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
    var xpcBundle: Bundle { get }
    var proxy: Any? { get }
    mutating func receive(xpcConnection: NSXPCConnection)
}
