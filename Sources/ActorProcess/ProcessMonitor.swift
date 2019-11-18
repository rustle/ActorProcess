//
//  ProcessMonitor.swift
//
//  Copyright © 2018-2019 Doug Russell. All rights reserved.
//

import Foundation

class ProcessMonitor {
    private let process: Process
    var didExit: ((ProcessMonitor) -> Void)?
    init(process: Process) {
        self.process = process
    }
    private var source: DispatchSourceProcess?
    func schedule() {
        source = DispatchSource
            .makeProcessSource(identifier: pid_t(process.processIdentifier),
                               eventMask: .exit,
                               queue: .main)
        source?.setEventHandler { [weak self] in
            guard let self = self else {
                return
            }
            self.didExit?(self)
            self.unschedule()
        }
        source?.setCancelHandler { [weak self] in
            self?.didExit = nil
        }
        source?.resume()
    }
    func unschedule() {
        source?.cancel()
        source = nil
    }
}
