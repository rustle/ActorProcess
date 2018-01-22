//
//  Actor.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

public class Actor<ProxyType> {
    public let identifier: String
    public private(set) var config: Config<ProxyType>
    public var proxy: ProxyType? {
        return config.proxy
    }
    public var processIdentifier: Int {
        return Int(process.processIdentifier)
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
            stateDidChange?(state)
        }
    }
    public var stateDidChange: ((State) -> Void)?
    private let process: Process
    private var monitor: ProcessMonitor?
    private var launchTime: CFAbsoluteTime?
    private var exitTime: CFAbsoluteTime?
    public init(identifier: String = UUID().uuidString, config: Config<ProxyType>) {
        self.identifier = identifier
        self.config = config
        process = Process()
    }
    public func launch() {
        switch state {
        case .new:
            break
        default:
            return
        }
        launchTime = CFAbsoluteTimeGetCurrent()
        process.launchPath = config.xpcBundle.executablePath
        process.environment = [
            "DYLD_FRAMEWORK_PATH" : config.xpcBundle.privateFrameworksPath!
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
        AgentConnection.shared.resume()
        AgentConnection.shared.proxy?.handshake(endpoint: nil, identifier: identifier) { [weak self] endpoint in
            guard let endpoint = endpoint else {
                return
            }
            DispatchQueue.main.async {
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
        
    }
    public func terminate() {
        process.terminate()
        state = .exited(.expected)
    }
    private func receive(endpoint: NSXPCListenerEndpoint) {
        let connection = NSXPCConnection(listenerEndpoint: endpoint)
        connection.remoteObjectInterface = config.interface
        connection.resume()
        config.receive(connection: connection)
        state = .connected
    }
}

extension Actor : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "Actor<\(ProxyType.self)> \(process.processIdentifier) \(identifier)"
    }
}

public extension Actor {
    public struct Config<ProxyType> {
        public var interface: NSXPCInterface {
            return impl.interface
        }
        public var connection: NSXPCConnection? {
            return impl.connection
        }
        public var xpcBundle: Bundle {
            return impl.xpcBundle
        }
        public var proxy: ProxyType? {
            return impl.proxy as? ProxyType
        }
        public mutating func receive(connection: NSXPCConnection) {
            impl.receive(connection: connection)
        }
        private var impl: ActorConfigImpl
        public init(impl: ActorConfigImpl) {
            self.impl = impl
        }
    }
}

public protocol ActorConfigImpl {
    var interface: NSXPCInterface { get }
    var connection: NSXPCConnection? { get }
    var xpcBundle: Bundle { get }
    var proxy: Any? { get }
    mutating func receive(connection: NSXPCConnection)
}
