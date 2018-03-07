//
//  Signal.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import Foundation

public protocol AnySignal : class {
    associatedtype T
    /// Subscribe to signal
    @discardableResult
    func subscribe(handler: @escaping Subscription<T>.Handler) -> Subscription<T>
    /// Call fire() method of all Subscriptions returned by subscribe(handler:)
    func fire(_ data: T)
    /// Call cancel() method of all Subscriptions returned by subscribe(handler:)
    func cancelAll()
    // MARK: Subscriptions Accessor Methods
    // It is inappropriate to call these directly
    var subscriptions: [Subscription<T>] { get }
    func append(subscription: Subscription<T>)
    func flush()
    func removeAll()
}

public extension AnySignal {
    @discardableResult
    public func subscribe(handler: @escaping Subscription<T>.Handler) -> Subscription<T> {
        let subscription = Subscription(handler: handler)
        append(subscription: subscription)
        return subscription
    }
    public func fire(_ data: T) {
        flush()
        for subscription in subscriptions {
            subscription.fire(data)
        }
    }
    public func cancelAll() {
        for subscription in subscriptions {
            subscription.cancel()
        }
        removeAll()
    }
}

public class Signal<T> : AnySignal {
    public var subscriptions = [Subscription<T>]()
    public func append(subscription: Subscription<T>) {
        subscriptions.append(subscription)
    }
    public func flush() {
        subscriptions = subscriptions.filter {
            return $0.handler != nil
        }
    }
    public func removeAll() {
        subscriptions.removeAll()
    }
}

public class Subscription<T> {
    public typealias Handler = (T) -> Void
    public typealias Dispose = () -> Void
    public typealias Filter = (T) -> Bool
    var handler: Handler?
    private var dispose: Dispose?
    private var queue: DispatchQueue?
    private var filter: Filter?
    private var sampler: Sampler<T>?
    public init(handler: @escaping Handler) {
        self.handler = handler
    }
    @discardableResult
    public func dispose(_ dispose: @escaping Dispose) -> Self {
        self.dispose = dispose
        return self
    }
    @discardableResult
    public func queue(_ queue: DispatchQueue) -> Self {
        self.queue = queue
        return self
    }
    @discardableResult
    public func filter(_ filter: @escaping Filter) -> Self {
        self.filter = filter
        return self
    }
    @discardableResult
    public func sample(every interval: TimeInterval) -> Self {
        if sampler == nil {
            sampler = Sampler()
            sampler?.fire = { [weak self] data in
                self?.actuallyFire(data)
            }
            sampler?.queue = queue
        }
        sampler?.interval = interval
        return self
    }
    public func cancel() {
        if let dispose = dispose {
            if let queue = queue {
                queue.async {
                    dispose()
                }
            } else {
                dispose()
            }
        }
        handler = nil
        dispose = nil
    }
    internal func fire(_ data: T) {
        if let sampler = sampler {
            sampler.enqueue(data: data)
        } else {
            actuallyFire(data)
        }
    }
    private func actuallyFire(_ data: T) {
        guard let handler = handler else {
            return
        }
        if let queue = queue {
            queue.async {
                handler(data)
            }
        } else {
            handler(data)
        }
    }
}

infix operator ⏦ : AssignmentPrecedence

public func ⏦<T>(signal: Signal<T>, data: T) -> Void {
    signal.fire(data)
}

fileprivate class Sampler<T> {
    fileprivate var queue: DispatchQueue?
    fileprivate var interval: TimeInterval = 0.0
    fileprivate var fireImmediately = true
    fileprivate var fire: ((T) -> Void)?
    private var queuedData: T?
    fileprivate func enqueue(data: T) {
        if queuedData == nil, fireImmediately {
            immediateFire(data: data)
        } else if queuedData != nil {
            queuedData = data
        } else {
            queuedData = data
            after { [weak self] () -> Void in
                self?.delayedFire()
            }
        }
    }
    private func immediateFire(data: T) {
        guard let fire = fire else {
            return
        }
        if let queue = queue {
            queue.async {
                fire(data)
            }
        } else {
            fire(data)
        }
        fireImmediately = false
        after { [weak self] in
            self?.resetFireImmediately()
        }
    }
    private func resetFireImmediately() {
        guard queuedData == nil else {
            return
        }
        fireImmediately = true
    }
    private func delayedFire() {
        guard let fire = fire, let data = queuedData else {
            return
        }
        if let queue = queue {
            queue.async {
                fire(data)
            }
        } else {
            fire(data)
        }
        queuedData = nil
        fireImmediately = false
        after { [weak self] in
            self?.resetFireImmediately()
        }
    }
    private func after(_ block: @escaping () -> Void) {
        (queue ?? DispatchQueue.main).asyncAfter(deadline: .now() + .milliseconds(Int(interval * 1000)), execute: block)
    }
}
