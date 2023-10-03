// This code was kindly provided by BXLR (Charles)
//
//  MessageGlue.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 02/10/2023.
//

import Foundation

enum SelectedProtocol {
    case ninebot
    case ninebotCrypto
    case xiaomi
    case xiaomiCrypto
}

class MessageGlue {
    private var preamble: [UInt8] = [UInt8](repeating: 0, count: 2)
    private var readFromPayload: Int = 0
    private var leftToRead: Int = 0
    private var fullMessage: [UInt8]?
    private var payloadSize: Int

    init(selectedProtocol: SelectedProtocol, payloadSize: Int) {
        self.payloadSize = payloadSize
        switch selectedProtocol {
        case .ninebot:
            preamble[0] = 0x5A
            preamble[1] = 0xA5
            readFromPayload = 9
        case .ninebotCrypto:
            preamble[0] = 0x5A
            preamble[1] = 0xA5
            readFromPayload = 13
        case .xiaomi:
            preamble[0] = 0x55
            preamble[1] = 0xAA
            readFromPayload = 6
        case .xiaomiCrypto:
            preamble[0] = 0x55
            preamble[1] = 0xAB
            readFromPayload = 16
        }
    }

    func put(data: [UInt8]) -> [UInt8]? {
        guard data.count > 0 else { return nil }
        if fullMessage != nil, leftToRead > 0 {
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
