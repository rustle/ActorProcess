//
//  ExampleConfig.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import ActorProcess

struct ExampleConfigImpl : ActorConnectionConfigurationImpl {
    static func config(identifier: Int) -> ActorConnection<ExampleMessaging>.Configuration<ExampleMessaging> {
        return ActorConnection.Configuration(impl: ExampleConfigImpl(identifier: identifier))
    }
    enum Error : Swift.Error {
        case unableToLoadBundle
    }
    func xpcBundle() throws -> Bundle {
        guard var url = Bundle.main.executableURL else {
            throw ExampleConfigImpl.Error.unableToLoadBundle
        }
        url.deleteLastPathComponent()
        url.appendPathComponent("ExampleActor.xpc")
        guard let bundle = Bundle(url: url) else {
            throw ExampleConfigImpl.Error.unableToLoadBundle
        }
        return bundle
    }
    var interface: NSXPCInterface {
        return NSXPCInterface(with: ExampleMessaging.self)
    }
    var xpcConnection: NSXPCConnection?
    var proxy: Any?
    mutating func receive(xpcConnection: NSXPCConnection) {
        guard let proxy = xpcConnection.remoteObjectProxy as? ExampleMessaging else {
            return
        }
        self.proxy = proxy
        self.xpcConnection = xpcConnection
        proxy.connect(identifier: self.identifier)
    }
    private let identifier: Int
    private init(identifier: Int) {
        self.identifier = identifier
    }
}
