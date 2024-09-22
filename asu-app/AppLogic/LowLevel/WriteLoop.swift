//
//  WriteLoop.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 13/07/2024.
//

import Foundation
import OrderedCollections

fileprivate enum QueueItem {
    class Every {
        private var count: Int
        private var limit: Int?
        private var limitHit: (() -> ())
        private var timer: Timer?
        
        init(
            getData: @escaping () -> (Data),
            frequency: Double,
            limit: Int?,
            limitHit: (() -> ())?,
            addFunction: @escaping (Data) async -> ()
        ) {
            precondition(frequency >= 0.2, "WriteLoop: .every message frequency must be at least 0.2")
            
            self.count = 0
            self.limit = limit
            self.limitHit = limitHit ?? {}
            self.timer = Timer(timeInterval: frequency, repeats: true) { _ in
                self.enqueue(getData: getData, addFunction: addFunction)
            }
            RunLoop.main.add(self.timer!, forMode: .default)
            self.enqueue(getData: getData, addFunction: addFunction)
        }
        
        func stop() {
            self.timer?.invalidate()
            self.timer = nil
        }
        
        func shouldDispose() -> Bool {
            // i'm certain there's a better way to write this function but i'm far too eepy to deal with that.
            guard let limit = self.limit else {
                return self.timer == nil && self.limitHit() == ()
            }
            return (self.timer == nil || self.count >= limit) && self.limitHit() == ()
        }
        
        private func enqueue(
            getData: @escaping () -> (Data),
            addFunction addToQueue: @escaping (Data) async -> ()
        ) {
            if self.limit == nil || self.count < self.limit ?? 0 {
                Task {
                    let data = getData()
                    await addToQueue(data)
                }
            } else {
                self.timer?.invalidate()
                self.timer = nil
            }
            
            self.count += 1
        }
    }
    
    class Limited {
        private enum Limit {
            case none
            case time(expiry: DispatchTime, limitHit: () -> ())
            case count(limit: Int, limitHit: () -> ())
        }
        
        private let limit: Limit
        private var count: Int?
        
        init() {
            self.limit = .none
        }
        
        init(timeLimit: Float, limitHit: (() -> ())?) {
            self.limit = .time(expiry: DispatchTime.distantFuture.advanced(by: .milliseconds(Int(timeLimit * 1000))), limitHit: limitHit ?? {})
        }
        
        init(countLimit: Int, limitHit: (() -> ())?) {
            self.limit = .count(limit: countLimit, limitHit: limitHit ?? {})
            self.count = 0
        }
        
        func shouldDispose() -> Bool {
            return switch self.limit {
            case .none: false
            case .time(let expiry, let limitHit): DispatchTime.now() >= expiry && limitHit() == ()
            case .count(let limit, let limitHit): self.count ?? 0 >= limit && limitHit() == ()
            }
        }
        
        func used() {
            self.count? += 1
        }
    }
    
    func shouldDispose() -> Bool {
        return switch self {
        case let .every(item): item.shouldDispose()
        case let .forever(_, item): item.shouldDispose()
        case let .condition(_, condition, item): !condition() || item.shouldDispose()
        }
    }
    
    case every(Every)
    case forever(() -> (Data), Limited)
    case condition(() -> (Data), () -> (Bool), Limited)
}

actor WriteLoop {
    enum WriteType {
        /// once.
        case once
        /// every x seconds (if this is too frequent, you WILL indefinitely block any other request. we crash if this is less than 0.2)
        case every(every: Double)
        /// every x seconds x times (if this is too frequent, the write loop will QUICKLY slow to a crawl. we crash if this is less than 0.2)
        case everyLimit(every: Double, times: Int, limitHit: (() -> ())? = nil)
        /// forever (pass void. here for the overload)
        case forever
        /// forever, until x seconds
        case foreverLimitSeconds(until: Float, limitHit: (() -> ())? = nil)
        /// forever, until x time
        case foreverLimitTimes(times: Int, limitHit: (() -> ())? = nil)
        /// until the condition is false (always done at least once)
        case condition(condition: () -> (Bool))
        /// until the condition is false, until x seconds (always done at least once)
        case conditionLimitSeconds(condition: () -> (Bool), until: Float, limitHit: (() -> ())? = nil)
        /// until the condition is false, until x seconds (always done at least once)
        case conditionLimitTimes(condition: () -> (Bool), times: Int, limitHit: (() -> ())? = nil)
    }
    
    enum WriteCharacteristic {
        case serial
        case upnp
        case avdtp
    }

    private var task: Task<(), Error>?
    
    // continuation stuff
    private var continuation: CheckedContinuation<Bool, Never>?
    private var continuationTimer: Timer?
    
    // queued items
    private var queueOfEveries: [QueueItem.Every] = []
    private var queue: [(WriteCharacteristic, UUID, QueueItem)] = []
    
    // write queues
    private var writeQueue: OrderedDictionary<UUID, (WriteCharacteristic, Data)> = [:]
    
    // quick access
    private let characteristics: [WriteCharacteristic] = [.serial, .upnp, .avdtp]
    
    // public funcs
    func start(serialWrite: @escaping (Data) -> (), upnpWrite: @escaping (Data) -> (), avdtpWrite: @escaping (Data) -> ()) {
        self.task = Task(priority: .high) {
            while !Task.isCancelled {
                if await self.shouldContinue() {
                    self.handleLoop(serialWrite, upnpWrite, avdtpWrite)
                }
            }
        }
    }
    
    func stop(clear: Bool = true) {
        // cancel the task
        task?.cancel()
        
        // cancel the fallback timer
        self.continuationTimer?.invalidate()
        self.continuationTimer = nil
        
        if clear {
            // get rid of queues
            self.queueOfEveries.forEach { item in item.stop() }
            self.queueOfEveries = []
            self.queue = []
            self.writeQueue = [:]
        }
        
        // resume any remaining continuations indicating to not continue
        self.continuation?.resume(returning: false)
        self.continuation = nil
    }
    
    func ready() {
        // reset fallback timer as we only want to fire `fallbackMessageFrequency` seconds
        // after the previous fire.
        self.continuationTimer?.invalidate()
        self.continuationTimer = Timer(timeInterval: fallbackMessageFrequency, repeats: true) { _ in
            Task {
                await self.doContinue()
            }
        }
        RunLoop.main.add(self.continuationTimer!, forMode: .default)
        self.doContinue()
    }
    
    func enqueue(writeType: WriteType, characteristic: WriteCharacteristic, getData: @escaping () -> (Data)) {
        switch writeType {
        case .once: self.writeQueue[UUID()] = (characteristic, getData())
        case .every(every: let every):
            let item = QueueItem.Every(getData: getData, frequency: every, limit: nil, limitHit: nil) { data in
                self.writeQueue[UUID()] = (characteristic, getData())
            }
            self.queueOfEveries.append(item)
        case .everyLimit(every: let every, times: let times, let limitHit):
            let item = QueueItem.Every(getData: getData, frequency: every, limit: times, limitHit: limitHit) { data in
                self.writeQueue[UUID()] = (characteristic, getData())
            }
            self.queueOfEveries.append(item)
        case .forever:
            enqueueSingle(characteristic, .forever(getData, .init()))
        case .foreverLimitSeconds(until: let until, let limitHit):
            enqueueSingle(characteristic, .forever(getData, .init(timeLimit: until, limitHit: limitHit)))
        case .foreverLimitTimes(times: let times, let limitHit):
            enqueueSingle(characteristic, .forever(getData, .init(countLimit: times, limitHit: limitHit)))
        case .condition(condition: let condition):
            enqueueSingle(characteristic, .condition(getData, condition, .init()))
        case .conditionLimitSeconds(condition: let condition, until: let until, let limitHit):
            enqueueSingle(characteristic, .condition(getData, condition, .init(timeLimit: until, limitHit: limitHit)))
        case .conditionLimitTimes(condition: let condition, times: let times, let limitHit):
            enqueueSingle(characteristic, .condition(getData, condition, .init(countLimit: times, limitHit: limitHit)))
        }
    }
    
    // private funcs
    private func shouldContinue() async -> Bool {
        return await withCheckedContinuation { checkedContinuation in
            // there being an unresumed continuation should be impossible, but if
            // there is, something went horribly wrong. cancel it and don't attempt
            // continuing. in fact perhaps maybe i should even crash the app if that
            // happens so that i catch it in the future, but this is a bit more
            // graceful.
            self.continuation?.resume(returning: false)
            self.continuation = checkedContinuation
        }
    }
    
    // this exists here to not duplicate logic but also not to prevent deep
    // recursion (which plagued the old write loop and made it crash after
    // a couple thousand messages...)
    private func doContinue() {
        continuation?.resume(returning: true)
        self.continuation = nil
    }
    
    // TODO: if ble write fails requeue without testing any conditions or anything for removal
    private func handleLoop(_ serialWrite: (Data) -> (), _ upnpWrite: (Data) -> (), _ avdtpWrite: (Data) -> ()) {
        self.queueOfEveries.removeAll { item in item.shouldDispose() }
        self.queue.removeAll { _, _, item in item.shouldDispose() }
        
        if !self.writeQueue.isEmpty {
            let (_, (characteristic, data)) = self.writeQueue.removeFirst()
            switch characteristic {
            case .serial: serialWrite(data)
            case .upnp: upnpWrite(data)
            case .avdtp: avdtpWrite(data)
            }
        }
        
        self.requeueAsNeeded()
    }
    
    private func enqueueSingle(_ characteristic: WriteCharacteristic, _ item: QueueItem) {
        self.queue.append((characteristic, UUID(), item))
    }
    
    // this could be greatly optimised, but i doubt we'll EVER have any more than 15 (and even 15 is unrealistic).
    // not worth it, but maybe if i repurpose this for future project i should keep this in mind.
    //
    // this applies not just to this function, but also the inefficient FIFO queue, and just this class in general
    /// requeues things into the write loop if needed
    private func requeueAsNeeded() {
        for (characteristic, uuid, queueItem) in self.queue {
            if self.writeQueue[uuid] == nil {
                switch queueItem {
                case .every: continue
                case let .forever(getData, item), let .condition(getData, _, item):
                    item.used()
                    self.writeQueue[uuid] = (characteristic, getData())
                }
            }
        }
    }
}
