//
//  Agent.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import os.log

public class Agent : NSObject, AgentMessaging, NSXPCListenerDelegate {
    public static let shared = Agent()
    private let auditSessionIdentifier: au_asid_t
    private var handshakeEndpoints = [String:((NSXPCListenerEndpoint?) -> Void, NSXPCListenerEndpoint?)]()
    @objc public func connect() {
        
    }
    @objc public func handshake(endpoint: NSXPCListenerEndpoint?, identifier: String, reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        if let (otherReply, otherEndpoint) = handshakeEndpoints.removeValue(forKey: identifier) {
            reply(otherEndpoint)
            otherReply(endpoint)
        } else {
            handshakeEndpoints[identifier] = (reply, endpoint)
        }
    }
    private var publishedEndpoints = [String:NSXPCListenerEndpoint]()
    @objc public func publish(endpoint: NSXPCListenerEndpoint, identifier: String) {
        publishedEndpoints[identifier] = endpoint
    }
    @objc public func publishedEndpoint(identifier: String, reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        reply(publishedEndpoints[identifier])
    }
    @objc public func listener(_ listener: NSXPCListener,
                               shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        guard newConnection.auditSessionIdentifier == auditSessionIdentifier else {
            return false
        }
        newConnection.exportedInterface = NSXPCInterface(with: AgentMessaging.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
    private let listener: NSXPCListener
    private override init() {
        let arguments = ProcessInfo.processInfo.arguments
        guard var index = arguments.index(where: { $0 == "--auditSessionIdentifier" }) else {
            exit(EXIT_FAILURE)
        }
        index += 1
        guard arguments.count > index else {
            exit(EXIT_FAILURE)
        }
        guard let pid = au_asid_t(arguments[index]) else {
            exit(EXIT_FAILURE)
        }
        auditSessionIdentifier = pid
        listener = NSXPCListener(machServiceName: "com.rustle.SpeakUp.act")
        super.init()
        listener.delegate = self
    }
    @objc public func resume() {
        listener.resume()
    }
}
