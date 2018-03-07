//
//  SignalsTests.swift
//
//  Copyright © 2018 Doug Russell. All rights reserved.
//

import XCTest
@testable import Signals

class Foo : NSObject {
    @objc dynamic var foo: String?
}

class SignalsTests: XCTestCase {
    func testKVOSignalSubscription() {
        let expectation = self.expectation(description: "foo")
        let foo = Foo()
        let observable = KeyValueObservable(object: foo, keyPath: #keyPath(Foo.foo))
        let observer = KeyValueObserverSignal<String>()
        observer.subscribe { value in
            XCTAssertEqual("foo", value)
            expectation.fulfill()
        }
        observable.add(observer: observer)
        foo.foo = "foo"
        self.waitForExpectations(timeout: 1.0) { _ in
            
        }
    }
    func testSample() {
        let expectation = self.expectation(description: "fired")
        let signal = Signal<String>()
        var count = 0
        let sub = signal.subscribe { _ in
            count += 1
            if count == 2 {
                expectation.fulfill()
            }
            if count == 3 {
                XCTFail()
            }
        }.sample(every: 1.0)
        signal⏦"foo"
        signal⏦"foo"
        signal⏦"foo"
        self.waitForExpectations(timeout: 2.0) { _ in
            
        }
        sub.cancel()
    }
    func testDispose() {
        let firedExpectation = self.expectation(description: "fired")
        let disposedExpectation = self.expectation(description: "fired")
        let signal = Signal<String>()
        let sub = signal.subscribe { _ in
            firedExpectation.fulfill()
        }
        .dispose {
            disposedExpectation.fulfill()
        }
        signal⏦"foo"
        sub.cancel()
        self.waitForExpectations(timeout: 1.0) { _ in
            
        }
    }
    func testCancel() {
        let signal = Signal<String>()
        var count = 0
        let sub = signal.subscribe { _ in
            count += 1
        }
        sub.cancel()
        signal⏦"foo"
        XCTAssertEqual(count, 0)
    }
    func testDoubleCancelDispose() {
        let firedExpectation = self.expectation(description: "fired")
        let disposedExpectation = self.expectation(description: "fired")
        let signal = Signal<String>()
        let sub = signal.subscribe { _ in
            firedExpectation.fulfill()
        }
        .dispose {
            disposedExpectation.fulfill()
        }
        signal⏦"foo"
        sub.cancel()
        sub.cancel()
        self.waitForExpectations(timeout: 1.0) { _ in
            
        }
    }
}
