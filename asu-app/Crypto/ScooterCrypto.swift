//
//  ScooterCrypto.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 07/10/2023.
//

import Foundation
import CoreBluetooth
import CryptoKit

fileprivate let debugnbcrypto = false
class ScooterCrypto {
    var paired: Bool {
        switch(self.scooterProtocol) {
        case .ninebot(true): self.ninebotPairing.paired
        case .xiaomi(true): self.xiaomiPairing.paired
        default: true
        }
    }
    var awaitingButtonPress: Bool {
        switch(self.scooterProtocol) {
        case .xiaomi(true): self.xiaomiPairing.awaitingButtonPress
        default: false
        }
    }
    
    // TODO: make the cryptos and pairings extend some generic maybe?
    private var ninebotCrypto: NinebotCrypto
    private var ninebotPairing: NinebotPairing
    private var xiaomiCrypto: XiaomiCrypto
    private var xiaomiPairing: XiaomiPairing
    private var scooterProtocol: ScooterProtocol
    
    init() {
        self.ninebotCrypto = .init(debugnbcrypto)
        self.ninebotPairing = .init()
        self.xiaomiCrypto = .init()
        self.xiaomiPairing = .init()
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
        self.ninebotCrypto.Reset()
        self.ninebotPairing = .init()
        self.xiaomiCrypto = .init() // TODO: replace with a reset (in case fallback key was used, we don't want to be regenerating it every reconnect)
        self.xiaomiPairing = .init()
        self.scooterProtocol = .ninebot(true)
    }
    
    // TODO: get rid of all of these single checks, and do some sort of catch-all
    func getPublicKey(withRemoteInfo remoteInfo: Data) -> Data {
        switch(self.scooterProtocol) {
        case .xiaomi(true):
            self.xiaomiCrypto.getPublicKey(withRemoteInfo: remoteInfo)
        default: Data()
        }
    }
    
    func generateSecret(withRemoteKey remoteKey: Data) -> SharedKey? {
        switch(self.scooterProtocol) {
        case .xiaomi(true):
            self.xiaomiCrypto.generateSecret(withRemoteKey: remoteKey)
        default: nil
        }
    }
    
    func calculateEncryptionKeys(keys: Data) -> (info: Data, expectedRemoteInfo: Data)? {
        switch(self.scooterProtocol) {
        case .xiaomi(true):
            let validationInfo = self.xiaomiCrypto.calculateEncryptionKeys(keys: keys)
            return validationInfo
        default: return nil
        }
    }
    
    func calculateDid(withRemoteKey remoteKey: Data) -> Data? {
        switch(self.scooterProtocol) {
        case .xiaomi(true):
            self.xiaomiCrypto.calculateDid(withRemoteKey: remoteKey)
        default: nil
        }
    }
    
    func encrypt(_ data: Data) -> Data {
        switch(self.scooterProtocol) {
        case .ninebot(true):
            let encrypted = self.ninebotCrypto.Encrypt(data.bytes)
            return Data(encrypted ?? data.bytes)
        case .xiaomi(true):
            print("encrypt fuck")
            fallthrough
        default:
            return Data(data)
        }
    }
    
    func decrypt(_ data: Data) -> Data {
        switch(self.scooterProtocol) {
        case .ninebot(true):
            guard let decrypted = self.ninebotCrypto.Decrypt(data.bytes) else {
                return Data(data)
            }
            return Data(decrypted)
        case .xiaomi(true):
            print("decrypt fuck")
            fallthrough
        default:
            return Data(data)
        }
    }
    
    func startPairing(withScooterManager scooterManager: ScooterManager) {
        switch(self.scooterProtocol) {
        case .ninebot(true):
            guard !self.ninebotPairing.paired else {
                return
            }
            
            self.ninebotPairing.startPairing(withScooterManager: scooterManager)
        case .xiaomi(true):
            guard !self.xiaomiPairing.paired else {
                return
            }
            
            self.xiaomiPairing.startPairing(withScooterManager: scooterManager)
        default: return
        }
    }
    
    func continuePairing(withScooterManager scooterManager: ScooterManager, received data: Data, forCharacteristic uuid: CBUUID) {
        switch (self.scooterProtocol) {
        case .ninebot(true):
            self.ninebotPairing.continuePairing(withScooterManager: scooterManager, received: data, forCharacteristic: uuid)
        case .xiaomi(true):
            self.xiaomiPairing.continuePairing(withScooterManager: scooterManager, received: data, forCharacteristic: uuid)
        default: return
        }
    }
}
