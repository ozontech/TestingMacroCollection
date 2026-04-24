//
//  AtomicLock.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import Foundation

public final class AtomicLock {
    private let lock = NSLock()

    public func performLockedAction(_ action: () -> Void) {
        lock.lock()
        action()
        lock.unlock()
    }

    public init() {}
}
