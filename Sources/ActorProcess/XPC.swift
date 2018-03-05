//
//  XPC.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation

public enum NSXPCConnectionError : Error {
    case auditionSessionMismatch
    case typeError
    case identifierMismatch
}

public extension NSXPCConnection {
    public func validate(teamIdentifier: String, auditSessionIdentifier: au_asid_t) throws {
        guard self.auditSessionIdentifier == auditSessionIdentifier else {
            throw NSXPCConnectionError.auditionSessionMismatch
        }
#if !DEBUG // Release only for now
        let processIdentifier = self.processIdentifier
        let attributes = [ kSecGuestAttributePid as String : NSNumber(value: processIdentifier) ]
        let client = try SecCode.client(attributes, flags: [])
        let appleSignedRequirements = "anchor apple generic and (certificate leaf[field.1.2.840.113635.100.6.1.9] or (certificate 1[field.1.2.840.113635.100.6.2.6] and certificate leaf[field.1.2.840.113635.100.6.1.13]))"
        let requirement = try SecRequirement.requirement(appleSignedRequirements, flags: [])
        try client.checkValidity(requirement: requirement, flags: [])
        let information = try client.signingInformation(flags: [.signingInformation, .requirementInformation])
        guard let identifier = information[kSecCodeInfoTeamIdentifier as String] as? String else {
            throw NSXPCConnectionError.typeError
        }
        guard teamIdentifier == identifier else {
            throw NSXPCConnectionError.identifierMismatch
        }
#endif
    }
}
