//
//  main.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import ActorProcess

Run().handshake(exportedInterfaceProtocol: ExampleMessaging.self,
                exportedObjectClass: Example.self)
