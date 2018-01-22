//
//  ProcessMonitor.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation

fileprivate func processMonitorCallback(fileDescriptor: CFFileDescriptor?, options: CFOptionFlags, context: UnsafeMutableRawPointer?) {
    guard let context = context else {
        return
    }
    let monitor = context.load(as: ProcessMonitor.self)
    if let didExit = monitor.didExit {
        didExit(monitor)
    }
}

class ProcessMonitor {
    private let process: Process
    private var unsafePointer: UnsafeMutablePointer<ProcessMonitor>?
    var didExit: ((ProcessMonitor) -> Void)?
    init(process: Process) {
        self.process = process
    }
    deinit {
        unsafePointer?.deinitialize()
        unsafePointer?.deallocate(capacity: 1)
    }
    private var queue: KernelQueue?
    private var fileDescriptor: CFFileDescriptor?
    private var runLoopSource: CFRunLoopSource?
    func schedule() {
        let pointer = UnsafeMutablePointer<ProcessMonitor>.allocate(capacity: 1)
        pointer.initialize(to: self)
        unsafePointer = pointer
        let queue = KernelQueue()
        let change = KernelEvent(identifer: Int(process.processIdentifier), filter: EVFILT_PROC, flags: EV_ADD | EV_RECEIPT, filterFlags: NOTE_EXIT, filterData: 0, userData: nil)
        queue.event(change: change, event: change)
        let fileDescriptor = queue.fileDescriptor(callback: processMonitorCallback, info: pointer)
        guard let runLoopSource = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, fileDescriptor, 0) else {
            return
        }
        self.queue = queue
        self.fileDescriptor = fileDescriptor
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        CFFileDescriptorEnableCallBacks(fileDescriptor, kCFFileDescriptorReadCallBack)
    }
    func unschedule() {
        self.queue = nil
        if let fileDescriptor = fileDescriptor {
            CFFileDescriptorDisableCallBacks(fileDescriptor, kCFFileDescriptorReadCallBack)
            self.fileDescriptor = nil
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            self.runLoopSource = nil
        }
    }
}
