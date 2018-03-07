//
//  main.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import ActorProcess

let serviceManager = ExampleServiceManager(identifier: "example")
let service = serviceManager.connect(identifier: 10)
service.connection.stateSignal.subscribe { [weak service] state in
    switch state {
    case .new:
        break
    case .running:
        break
    case .connected:
        service?.connection.proxy?.exampleMessage()
    case .exited(_):
        break
    }
}.queue(DispatchQueue.global())
withExtendedLifetime(serviceManager) {
    dispatchMain()
}
