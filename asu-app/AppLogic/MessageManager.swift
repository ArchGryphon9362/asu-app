//
//  MessageManager.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/02/2024.
//

import Foundation

enum ParsedNinebotMessage {
    case ninebotMessage(NinebotMessage)
    case ninebotWriteAck(NinebotMessage)
}

class MessageManager {
    var scooterProtocol: ScooterProtocol
    
    init(scooterProtocol: ScooterProtocol) {
        self.scooterProtocol = scooterProtocol
    }
    
    func ninebotParse(_ data: Data) -> ParsedNinebotMessage? {
        switch self.scooterProtocol {
        case .xiaomi:
            guard data.count >= 4 else {
                return nil
            }
            let cmd = data[3 + 0x01]
            let addr = data[3 + 0x02]
            let payload = data[(3 + 0x03)...]
            
            switch cmd {
            case 0x04:
                guard let message = NinebotMessage.parse(payload, address: addr) else {
                    return nil
                }
                if case var .infoDump(infoDump) = message {
                    infoDump.speed /= 100 // why does xiaomi have to be stupid??
                    return .ninebotMessage(.infoDump(infoDump))
                }
                return .ninebotMessage(message)
            case 0x05:
                guard let messageType = NinebotMessage.getMessageType(address: addr) else {
                    return nil
                }
                return .ninebotWriteAck(messageType)
            default: return nil
            }
        default: // this is case ninebot, but also how i want it to act if some other scooter protocol is specified for whatever reason
            guard data.count >= 5 else {
                return nil
            }
            let cmd = data[3 + 0x02]
            let addr = data[3 + 0x03]
            let payload = Data(data[(3 + 0x04)...])
            
            switch cmd {
            case 0x01, 0x04:
                guard let message = NinebotMessage.parse(payload, address: addr) else {
                    return nil
                }
                return .ninebotMessage(message)
            case 0x02, 0x03, 0x05:
                guard let messageType = NinebotMessage.getMessageType(address: addr) else {
                    return nil
                }
                return .ninebotWriteAck(messageType)
            default: return nil
            }
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
