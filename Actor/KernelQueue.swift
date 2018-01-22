//
//  KernelQueue.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation
import Darwin.sys.event

public struct KernelQueue {
    private let kq = kqueue()
    public func event(change: KernelEvent, event: KernelEvent, timeout: TimeInterval? = nil) {
        var change = change.ke
        var event = event.ke
        kevent(kq, &change, 1, &event, 1, nil)
    }
    func fileDescriptor(callback: @escaping CFFileDescriptorCallBack, info: UnsafeMutableRawPointer?) -> CFFileDescriptor {
        var context = CFFileDescriptorContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)
        return withUnsafePointer(to: &context) { pointer in
            return CFFileDescriptorCreate(kCFAllocatorDefault, kq, true, callback, pointer)
        }
    }
}

public struct KernelEvent {
    fileprivate let ke: kevent
    /// identifier for this event
    public var identifer: Int {
        return Int(ke.ident)
    }
    /// filter for event
    public var filter: Int {
        return Int(ke.filter)
    }
    /// general flags
    public var flags: Int {
        return Int(ke.flags)
    }
    /// filter-specific flags
    public var filterFlags: Int {
        return Int(ke.fflags)
    }
    /// filter-specific data
    public var filterData: Int {
        return ke.data
    }
    /// opaque user data identifier
    public var userData: UnsafeMutableRawPointer? {
        return ke.udata
    }
    public init(identifer: Int, filter: Int32, flags: Int32, filterFlags: UInt32, filterData: Int, userData: UnsafeMutableRawPointer?) {
        ke = kevent(ident: UInt(identifer), filter: Int16(filter), flags: UInt16(flags), fflags: filterFlags, data: filterData, udata: userData)
    }
}
