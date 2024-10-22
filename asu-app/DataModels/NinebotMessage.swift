//
//  NinebotMessage.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/02/2024.
//

import Foundation

struct NinebotRegisterInfo {
    var address: UInt8
    var amount: UInt8 = 2
}

struct NinebotVersion: Equatable {
    let raw: Data
    var parsed: String {
        guard self.raw.count >= 2 else { return "" }
        
        let first  = (self.raw[0] & 0xF0) >> 4
        let second = (self.raw[0] & 0x0F) >> 0
        let third  = (self.raw[1] & 0xF0) >> 4
        let forth  = (self.raw[1] & 0x0F) >> 0
        
        let firstPart = first != 0 ? "\(first)." : ""
        let result = "\(second).\(third).\(forth)"
        return firstPart + result
    }
}

protocol NinebotMessage {
    static func parse(_ data: Data, address: UInt8) -> Self?
    func read() -> Data?
    func write(ack: Bool) -> Data?
}
