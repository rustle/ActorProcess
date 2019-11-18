//
//  Security.swift
//  
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Security

public enum SecCodeError : Error {
    case osStatus(Int)
    case typeError
}

public enum SecRequirementError : Error {
    case osStatus(Int)
}

public extension SecCode {
    static func client(_ attributes: [String:Any], flags: SecCSFlags) throws -> SecCode {
        var value: SecCode?
        let status = SecCodeCopyGuestWithAttributes(nil, attributes as CFDictionary, flags, &value)
        guard status == errSecSuccess, let client = value else {
            throw SecCodeError.osStatus(Int(status))
        }
        return client
    }
    func checkValidity(requirement: SecRequirement?, flags: SecCSFlags) throws {
        let status = SecCodeCheckValidity(self, flags, requirement)
        guard status == errSecSuccess else {
            throw SecCodeError.osStatus(Int(status))
        }
    }
    func signingInformation(flags: SecCSFlags) throws -> [String:Any] {
        var value: CFDictionary?
        let status = SecCodeCopySigningInformation(self as! SecStaticCode, flags, &value)
        guard status == errSecSuccess else {
            throw SecCodeError.osStatus(Int(status))
        }
        guard let information = value as? [String:Any] else {
            throw SecCodeError.typeError
        }
        return information
    }
}

public extension SecRequirement {
    static func requirement(_ requirement: String, flags: SecCSFlags) throws -> SecRequirement {
        var value: SecRequirement?
        let status = SecRequirementCreateWithString(requirement as CFString, flags, &value);
        guard status == errSecSuccess, let requirement = value else {
            throw SecRequirementError.osStatus(Int(status))
        }
        return requirement
    }
}

fileprivate struct SecCSFlagsStorage {
    fileprivate static let signingInformation = SecCSFlags(rawValue: kSecCSSigningInformation)
    fileprivate static let requirementInformation = SecCSFlags(rawValue: kSecCSRequirementInformation)
}

public extension SecCSFlags {
    static var signingInformation: SecCSFlags {
        SecCSFlagsStorage.signingInformation
    }
    static var requirementInformation: SecCSFlags {
        SecCSFlagsStorage.requirementInformation
    }
}
