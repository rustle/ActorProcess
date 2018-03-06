//
//  AT.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import ActorProcess

public class Example : NSObject, ExampleMessaging, ExportedObject {
    private let identifier: String
    private let connection: AgentConnection
    public required init(identifier: String, connection: AgentConnection) {
        self.identifier = identifier
        self.connection = connection
    }
    @objc public func connect(identifier: Int) {
        print("\(#function) \(identifier)")
    }
    @objc public func exampleMessage() {
        print(#function)
    }
}
