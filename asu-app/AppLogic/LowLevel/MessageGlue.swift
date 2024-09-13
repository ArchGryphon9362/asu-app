// This code was kindly provided by BXLR (Charles)
//
//  MessageGlue.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 02/10/2023.
//

import Foundation

class MessageGlue {
    private var preamble: [UInt8] {
        switch(self.scooterProtocol) {
        case .ninebot:
                return [0x5A, 0xA5]
        case .xiaomi:
            if self.scooterProtocol.crypto {
                return [0x55, 0xAA]
            } else {
                return [0x55, 0xAB]
            }
        }
    }
    private var readFromPayload: Int {
        switch(self.scooterProtocol) {
        case let .ninebot(crypto):
            if crypto {
                return 13
            } else {
                return 9
            }
        case let .xiaomi(crypto):
            if crypto {
                return 16
            } else {
                return 6
            }
        }
    }
    private var leftToRead: Int = 0
    private var fullMessage: [UInt8]?
    private var payloadSize: Int
    private var scooterProtocol: ScooterProtocol

    init(scooterProtocol: ScooterProtocol, payloadSize: Int) {
        self.payloadSize = payloadSize
        self.scooterProtocol = scooterProtocol
    }

    func put(data: [UInt8]) -> [UInt8]? {
        guard data.count > 0 else { return nil }
        if fullMessage != nil, leftToRead > 0, data.count <= leftToRead {
            let chunkLen = data.count
            for i in 0..<chunkLen {
                fullMessage![fullMessage!.count - leftToRead + i] = data[i]
            }
            leftToRead -= chunkLen
            if leftToRead == 0 {
                return fullMessage!
            }
        } else if data[0] == preamble[0] && data[1] == preamble[1] {
            fullMessage = nil
            leftToRead = 0
            let totalLen = Int(data[2]) + readFromPayload
            if totalLen > payloadSize {
                leftToRead = totalLen - payloadSize
                fullMessage = [UInt8](repeating: 0, count: totalLen)
                for i in 0..<payloadSize {
                    fullMessage![i] = data[i]
                }
            } else {
                fullMessage = nil
                leftToRead = 0
                return data
            }
        }
        return nil
    }
}
