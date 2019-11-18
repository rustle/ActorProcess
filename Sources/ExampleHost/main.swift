//
//  main.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import ActorProcess

let serviceManager = ExampleServiceManager(identifier: "example")
let service = serviceManager.connect(identifier: 10)
_ = service
    .connection
    .$state
    .receive(on: DispatchQueue.global())
    .sink { [weak service] state in
        switch state {
        case .new:
            break
        case .running:
            break
        case .connected:
            service?.connection.proxy?.exampleMessage()
            service?.connection.terminate()
        case .exited(_):
            break
        }
    }
withExtendedLifetime(serviceManager) {
    dispatchMain()
}
