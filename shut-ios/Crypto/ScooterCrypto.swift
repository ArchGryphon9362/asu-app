//
//  ScooterCrypto.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 07/10/2023.
//

import Foundation
import CoreBluetooth

private enum NinebotAuthState {
    case unpaired
    case awaitingStartResponse
    case awaitingButtonPress
    case awaitingFinishResponse
    case paired
}

class ScooterCrypto {
    var paired: Bool
    
    private var ninebotCrypto: NinebotCrypto
    private var ninebotAuthState: NinebotAuthState
    private var xiaomiCrypto: XiaomiCrypto
    private var scooterProtocol: ScooterProtocol
    
    init() {
        self.paired = false
        self.ninebotCrypto = .init()
        self.ninebotAuthState = .unpaired
        self.xiaomiCrypto = .init()
        self.scooterProtocol = .ninebot(true)
    }
    
    func setName(_ name: String) {
        var name = name
        
        if name.count < 12 {
            name = name.padding(toLength: 12, withPad: "\0", startingAt: 0)
        }

        self.ninebotCrypto.SetName(name)
        self.ninebotCrypto.Reset()
    }
    
    func setProtocol(_ scooterProtocol: ScooterProtocol) {
        self.scooterProtocol = scooterProtocol
    }
    
    func reset() {
        self.paired = false
        self.ninebotCrypto = .init()
        self.ninebotCrypto.Reset()
        self.ninebotAuthState = .unpaired
        self.xiaomiCrypto = .init()
        self.scooterProtocol = .ninebot(true)
    }
    
    func encrypt(_ data: [UInt8]) -> Data {
        switch(self.scooterProtocol) {
        case .ninebot(true):
            let encrypted = self.ninebotCrypto.Encrypt(data)
            return Data(encrypted ?? [])
        case .xiaomi(true):
            print("encrypt fuck")
            fallthrough
        default:
            return Data(data)
        }
    }
    
    func decrypt(_ data: Data) -> Data? {
        switch(self.scooterProtocol) {
        case .ninebot(true):
            guard let encrypted = self.ninebotCrypto.Decrypt(data.bytes) else {
                return nil
            }
            return Data(encrypted)
        case .xiaomi(true):
            print("decrypt fuck")
            fallthrough
        default:
            return Data(data)
        }
    }
    
    func startPairing(_ scooterManager: ScooterManager) {
        guard !self.paired else {
            return
        }
        
        switch(self.scooterProtocol) {
        case .ninebot(true):
            self.ninebotAuthState = .awaitingStartResponse
            
            scooterManager.write(Data(hex: "3e215b00")) { self.ninebotAuthState == .awaitingStartResponse }
        case .xiaomi(true):
            print("no no starting pairing on ximi")
            return
        default: return
        }
    }
    
    func continuePairing(_ scooterManager: ScooterManager, received data: Data, forCharacteristic uuid: CBUUID) {
        switch (self.scooterProtocol) {
        case .ninebot(true):
            guard uuid == serialRXCharUUID else {
                return
            }
            
            guard data.count > 6 else {
                return
            }
            
            let payloadLength = data[2 + 0x00]
            let src = data[2 + 0x01]
            let dst = data[2 + 0x02]
            let cmd = data[2 + 0x03]
            let arg = data[2 + 0x04]
            
            guard data.count - 0x07 >= payloadLength else {
                return
            }
            
            if (src == 0x21 &&
                dst == 0x3E &&
                cmd == 0x5B) {
                self.ninebotAuthState = .awaitingButtonPress
                scooterManager.write(Data(hex: "3e215c0000000000000000000000000000000000")) { self.ninebotAuthState == .awaitingButtonPress }
            }
            
            if (src == 0x21 &&
                dst == 0x3E &&
                cmd == 0x5C) {
                self.ninebotAuthState = .awaitingFinishResponse
                if (arg == 0x00) {
                    scooterManager.scooterBluetooth.setConnectionState(.pairing)
                }
                scooterManager.write(Data(hex: "3e215d00")) { self.ninebotAuthState == .awaitingFinishResponse }
            }
            
            if (src == 0x21 &&
                dst == 0x3E &&
                cmd == 0x5D &&
                arg == 0x01) {
                self.ninebotAuthState = .paired
                scooterManager.scooterBluetooth.setConnectionState(.connected)
            }
        case .xiaomi(true):
            print("oh boy oh fuck :/")
            print(dataToHex(data: data))
            return
        default:
            return
        }
    }
}
