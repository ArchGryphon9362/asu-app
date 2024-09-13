//
//  RawMessageManager.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/02/2024.
//

import Foundation

enum ParsedNinebotMessage {
    case stockNBMessage(StockNBMessage)
    case stockNBWriteAck(StockNBMessage)
    case shfwMessage(SHFWMessage)
    case shfwWriteAck(SHFWMessage)
}

class RawMessageManager {
    var scooterProtocol: ScooterProtocol
    
    init(scooterProtocol: ScooterProtocol) {
        self.scooterProtocol = scooterProtocol
    }
    
    func ninebotParse(_ data: Data) -> ParsedNinebotMessage? {
        let isXiaomi = if case .xiaomi(_) = self.scooterProtocol { true } else { false }
        let keyOffset = isXiaomi ? 0x04 : 0x05
        
        guard data.count >= keyOffset + 2 else {
            return nil
        }
        let cmd = data[keyOffset + 0x00]
        let addr = data[keyOffset + 0x01]
        let payload = Data(data[(keyOffset + 0x02)...])
        
        switch cmd {
        case 0x04:
            guard let message = StockNBMessage.parse(payload, address: addr) else {
                return nil
            }
            if case var StockNBMessage.infoDump(infoDump) = message, isXiaomi {
                infoDump.speed /= 100 // why does xiaomi have to be stupid??
                return .stockNBMessage(StockNBMessage.infoDump(infoDump))
            }
            return .stockNBMessage(message)
        case 0x05:
            guard let messageType = StockNBMessage.getMessageType(address: addr) else {
                return nil
            }
            return .stockNBWriteAck(messageType)
        case 0x34:
            guard let message = SHFWMessage.parse(payload, address: addr) else {
                return nil
            }
            return .shfwMessage(message)
        case 0x35:
            guard let messageType = SHFWMessage.getMessageType(address: addr, size: UInt8(payload.count)) else {
                return nil
            }
            return .shfwWriteAck(messageType)
        case 0x39:
            guard let message = SHFWMessage.parseNewVersion(payload) else {
                return nil
            }
            return .shfwMessage(message)
        default: return nil
        }
    }
    
    func ninebotRead(_ message: NinebotMessage) -> Data? {
        switch self.scooterProtocol {
        case let .xiaomi(crypto):
            guard let messageData = message.read() else {
                return nil
            }
            var result = Data()
            result.append(crypto ? xiaomiCryptHeader : xiaomiHeader)
            result.append(UInt8(messageData.count - 2))
            result.append(0x20)
            result.append(contentsOf: messageData)
            return result
        default: // this is case ninebot, but also how i want it to act if some other scooter protocol is specified for whatever reason
            guard let messageData = message.read() else {
                return nil
            }
            var result = Data()
            result.append(ninebotHeader)
            result.append(UInt8(messageData.count - 2))
            result.append(contentsOf: [0x3e, 0x20])
            result.append(contentsOf: messageData)
            return result
        }
    }
    
    func ninebotWrite(_ message: NinebotMessage, ack: Bool) -> Data? {
        switch self.scooterProtocol {
        case let .xiaomi(crypto):
            guard let messageData = message.write(ack: ack) else {
                return nil
            }
            var result = Data()
            result.append(crypto ? xiaomiCryptHeader : xiaomiHeader)
            result.append(UInt8(messageData.count - 2))
            result.append(0x20)
            result.append(contentsOf: messageData)
            return result
        default: // this is case ninebot, but also how i want it to act if some other scooter protocol is specified for whatever reason
            guard let messageData = message.write(ack: ack) else {
                return nil
            }
            var result = Data()
            result.append(ninebotHeader)
            result.append(UInt8(messageData.count - 2))
            result.append(contentsOf: [0x3e, 0x20])
            result.append(contentsOf: messageData)
            return result
        }
    }
}
