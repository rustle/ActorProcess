//
//  ExampleMessaging.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation

@objc public protocol ExampleMessaging {
    @objc func connect(identifier: Int)
    @objc func exampleMessage()
}
