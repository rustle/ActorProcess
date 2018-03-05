//
//  Agent.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import Security

public class Agent : NSObject, AgentMessaging, NSXPCListenerDelegate {
    public static let shared = Agent()
    private let auditSessionIdentifier: au_asid_t
    private var handshakeEndpoints = [String:((NSXPCListenerEndpoint?) -> Void, NSXPCListenerEndpoint?)]()
    private var publishedEndpoints = [String:NSXPCListenerEndpoint]()
    private var publishedEndpointsQueue = [String:[(NSXPCListenerEndpoint) -> Void]]()
    private let listener: NSXPCListener
    @objc public func handshake(endpoint: NSXPCListenerEndpoint?,
                                identifier: String,
                                reply: @escaping (NSXPCListenerEndpoint?) -> Void) {
        DispatchQueue.main.async {
            if let (otherReply, otherEndpoint) = self.handshakeEndpoints.removeValue(forKey: identifier) {
                reply(otherEndpoint)
                otherReply(endpoint)
            } else {
                self.handshakeEndpoints[identifier] = (reply, endpoint)
            }
        }
    }
    @objc public func publish(endpoint: NSXPCListenerEndpoint, identifier: String) {
        DispatchQueue.main.async {
            self.publishedEndpoints[identifier] = endpoint
            if let queued = self.publishedEndpointsQueue.removeValue(forKey: identifier) {
                for reply in queued {
                    reply(endpoint)
                }
            }
        }
    }
    @objc public func publishedEndpoint(identifier: String, reply: @escaping (NSXPCListenerEndpoint) -> Void) {
        DispatchQueue.main.async {
            if let endpoint = self.publishedEndpoints[identifier] {
                reply(endpoint)
            } else {
                if self.publishedEndpointsQueue[identifier] == nil {
                    self.publishedEndpointsQueue[identifier] = []
                }
                self.publishedEndpointsQueue[identifier]?.append(reply)
            }
        }
    }
    @objc public func listener(_ listener: NSXPCListener,
                               shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        #if !DEBUG // Release only for now
        do {
            try newConnection.validate(teamIdentifier: "", auditSessionIdentifier: auditSessionIdentifier)
        } catch {
            return false
        }
        #endif
        newConnection.exportedInterface = NSXPCInterface(with: AgentMessaging.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
    private override init() {
        let arguments = ProcessInfo.processInfo.arguments
        guard var auditIndex = arguments.index(where: { $0 == "--auditSessionIdentifier" }) else {
            exit(EXIT_FAILURE)
        }
        auditIndex += 1
        guard arguments.count > auditIndex else {
            exit(EXIT_FAILURE)
        }
        guard let audit = au_asid_t(arguments[auditIndex]) else {
            exit(EXIT_FAILURE)
        }
        auditSessionIdentifier = audit
        guard var nameIndex = arguments.index(where: { $0 == "--machServiceName" }) else {
            exit(EXIT_FAILURE)
        }
        nameIndex += 1
        guard arguments.count > nameIndex else {
            exit(EXIT_FAILURE)
        }
        let name = arguments[nameIndex]
        listener = NSXPCListener(machServiceName: name)
        super.init()
        listener.delegate = self
    }
    @objc public func resume() {
        listener.resume()
    }
}
