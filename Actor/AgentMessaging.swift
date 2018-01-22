//
//  AgentMessaging.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation

@objc
public protocol AgentMessaging {
    func connect()
    func handshake(endpoint: NSXPCListenerEndpoint?, identifier: String, reply: @escaping (NSXPCListenerEndpoint?) -> Void)
    func publish(endpoint: NSXPCListenerEndpoint, identifier: String)
    func publishedEndpoint(identifier: String, reply: @escaping (NSXPCListenerEndpoint?) -> Void)
}
