//
//  ScooterCrypto.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 07/10/2023.
//

import Foundation
import CoreBluetooth
import CryptoKit

fileprivate let debugnbcrypto = true
// TODO: convert to actor!!
class ScooterCrypto {
    var authenticated: Bool {
        switch(self.scooterProtocol) {
        case .ninebot(true): self.ninebotAuth.authenticated
        case .xiaomi(true): self.xiaomiAuth.authenticated
        default: true
        }
    }
    var awaitingButtonPress: Bool {
        switch(self.scooterProtocol) {
        case .xiaomi(true): self.xiaomiAuth.awaitingButtonPress
        default: false
        }
    }
    
    // TODO: make the cryptos and auths extend some generic maybe?
    private var ninebotCrypto: NinebotCrypto
    private var ninebotAuth: NinebotAuth
    private var xiaomiCrypto: XiaomiCrypto
    private var xiaomiAuth: XiaomiAuth
    private var scooterProtocol: ScooterProtocol
    
    init() {
        self.ninebotCrypto = .init(debug: debugnbcrypto)
        self.ninebotAuth = .init()
        self.xiaomiCrypto = .init()
        self.xiaomiAuth = .init(xiaomiCrypto: self.xiaomiCrypto)
        self.scooterProtocol = .ninebot(true)
    }
    
    func setName(_ name: String) {
        var name = name
        
        if name.count < 12 {
            name = name.padding(toLength: 12, withPad: "\0", startingAt: 0)
        }

        self.ninebotCrypto.setName(name)
    }
    
    func setProtocol(_ scooterProtocol: ScooterProtocol) {
        self.scooterProtocol = scooterProtocol
    }
    
    func reset() {
        self.ninebotCrypto.reset()
        self.ninebotAuth = .init()
        // TODO: why is mi crypto being reset multiple times??
        self.xiaomiCrypto.reset()
        self.xiaomiAuth = .init(xiaomiCrypto: self.xiaomiCrypto)
        self.scooterProtocol = .ninebot(true)
    }
    
    // TODO: make encrypt and decrypt return nil if failed and discard message if that's the result
    func encrypt(_ data: Data) -> Data {
        switch(self.scooterProtocol) {
        case .ninebot(true):
            let encrypted = self.ninebotCrypto.encrypt(data)
            return encrypted ?? data
        case .xiaomi(true):
            let encrypted = self.xiaomiCrypto.encrypt(data)
            return encrypted ?? data
        default:
            return Data(data)
        }
    }
    
    // TODO: return nil on failed decrypt
    func decrypt(_ data: Data) -> Data? {
        switch(self.scooterProtocol) {
        case .ninebot(true):
            guard let decrypted = self.ninebotCrypto.decrypt(data) else {
                return Data(data)
            }
            return Data(decrypted)
        case .xiaomi(true):
            guard let decrypted = self.xiaomiCrypto.decrypt(data) else {
                return Data(data)
            }
            return Data(decrypted)
        default:
            return Data(data)
        }
    }
    
    func startAuthenticating(withScooterManager scooterManager: ScooterManager) {
        switch(self.scooterProtocol) {
        case .ninebot(true):
            guard !self.ninebotAuth.authenticated else {
                return
            }
            
            self.ninebotAuth.startAuthenticating(withScooterManager: scooterManager)
        case .xiaomi(true):
            guard !self.xiaomiAuth.authenticated else {
                return
            }
            
            self.xiaomiAuth.startAuthenticating(withScooterManager: scooterManager)
        default: return
        }
    }
    
    func continueAuthenticating(withScooterManager scooterManager: ScooterManager, received data: Data, forCharacteristic uuid: CBUUID) -> ConnectionState? {
        switch (self.scooterProtocol) {
        case .ninebot(true):
            return self.ninebotAuth.continueAuthenticating(withScooterManager: scooterManager, received: data, forCharacteristic: uuid)
        case .xiaomi(true):
            return self.xiaomiAuth.continueAuthenticating(withScooterManager: scooterManager, received: data, forCharacteristic: uuid)
        default: return nil
        }
    }
}
