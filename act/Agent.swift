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
        #if !DEBUG // Release only for now
        do {
            try validate(connection: newConnection, identifier: "")
        } catch {
            return false
        }
        #endif
        newConnection.exportedInterface = NSXPCInterface(with: AgentMessaging.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
    public enum Error : Swift.Error {
        case auditionSessionMismatch
        case typeError
        case identifierMismatch
    }
    private func validate(connection: NSXPCConnection, identifier: String) throws {
        guard connection.auditSessionIdentifier == auditSessionIdentifier else {
            throw Agent.Error.auditionSessionMismatch
        }
        let processIdentifier = connection.processIdentifier
        let attributes = [ kSecGuestAttributePid as String : NSNumber(value: processIdentifier) ]
        let client = try SecCode.client(attributes, flags: [])
        let appleSignedRequirements = "anchor apple generic and (certificate leaf[field.1.2.840.113635.100.6.1.9] or (certificate 1[field.1.2.840.113635.100.6.2.6] and certificate leaf[field.1.2.840.113635.100.6.1.13]))"
        let requirement = try SecRequirement.requirement(appleSignedRequirements, flags: [])
        try client.checkValidity(requirement: requirement, flags: [])
        let information = try client.signingInformation(flags: [.signingInformation, .requirementInformation])
        guard let teamIdentifier = information[kSecCodeInfoTeamIdentifier as String] as? String else {
            throw Agent.Error.typeError
        }
        guard teamIdentifier == identifier else {
            throw Agent.Error.identifierMismatch
        }
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
