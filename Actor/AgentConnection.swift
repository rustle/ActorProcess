//
//  AgentConnection.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import Darwin.bsm.audit

public let agentIdentifier = "com.rustle.SpeakUp.act"
public let agentPlistName = "act.plist"

public class AgentConnection {
    static public func load() throws {
        let bundle = Bundle(for: AgentConnection.self)
        guard let agentPath = bundle.path(forResource: "act", ofType: nil) else {
            return
        }
        let applicationSupportURL = try FileManager.`default`.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let folderURL: URL
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            folderURL = applicationSupportURL.appendingPathComponent(bundleIdentifier).appendingPathComponent("Agent")
        } else {
            folderURL = applicationSupportURL.appendingPathComponent("Actor").appendingPathComponent("Agent")
        }
        if !FileManager.`default`.fileExists(atPath: folderURL.path) {
            try FileManager.`default`.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }
        // Load/Reload agent
        let plistURL = folderURL.appendingPathComponent(agentPlistName)
        let unload = Process()
        unload.launchPath = "/bin/launchctl"
        unload.arguments = ["unload", plistURL.path]
        unload.standardOutput = FileHandle.standardOutput
        unload.launch()
        unload.waitUntilExit()
        var info = auditinfo_addr()
        guard getaudit_addr(&info, Int32(MemoryLayout<auditinfo_addr>.size)) == 0 else {
            return
        }
        try ([
            "Label" : agentIdentifier,
            "ProgramArguments" : [
                agentPath,
                "--auditSessionIdentifier",
                String(info.ai_asid),
            ],
            "MachServices" : [ agentIdentifier : [:] ],
        ] as NSDictionary).write(to: plistURL)
        let load = Process()
        load.launchPath = "/bin/launchctl"
        load.arguments = ["load", plistURL.path]
        load.standardOutput = FileHandle.standardOutput
        load.launch()
        load.waitUntilExit()
    }
    public static let shared = AgentConnection()
    private let connection: NSXPCConnection
    public private(set) var proxy: AgentMessaging?
    private init() {
        connection = NSXPCConnection(machServiceName: "com.rustle.SpeakUp.act", options: [])
        connection.remoteObjectInterface = NSXPCInterface(with: AgentMessaging.self)
    }
    private var once = false
    public func resume() {
        if !once {
            connection.resume()
            proxy = connection.remoteObjectProxy as? AgentMessaging
            proxy?.connect()
            once = true
        }
    }
}
