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
        case .ninebot:
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
                return .ninebotMessage(message)
            case 0x05:
                guard let messageType = NinebotMessage.getMessageType(address: addr) else {
                    return nil
                }
                return .ninebotWriteAck(messageType)
            default: return nil
            }
        default: return nil
        }
    }
    
    func ninebotRead(_ message: NinebotMessage) -> Data {
        switch self.scooterProtocol {
        case let .xiaomi(crypto):
            let messageData = message.read()
            var result = Data()
            result.append(crypto ? xiaomiCryptHeader : xiaomiHeader)
            result.append(UInt8(messageData.count - 2))
            result.append(0x20)
            result.append(contentsOf: message.read())
            return result
        default: // this is case ninebot, but also how i want it to act if some other scooter protocol is specified
            let messageData = message.read()
            var result = Data()
            result.append(ninebotHeader)
            result.append(UInt8(messageData.count - 2))
            result.append(contentsOf: [0x3e, 0x20])
            result.append(contentsOf: message.read())
            return result
        }
    }
}
