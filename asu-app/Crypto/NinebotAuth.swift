//
//  NinebotAuth.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 08/10/2023.
//

import Foundation
import CoreBluetooth

private enum NinebotAuthState {
    case unauthenticated
    case start
    case buttonPress
    case finish
    case authenticated
}

// TODO: figure out why sometimes authentication just doesn't
class NinebotAuth {
    var authenticated: Bool {
        self.authState == .authenticated
    }
    
    private var authState: NinebotAuthState
    private var randomAuthData: Data
    
    init() {
        self.authState = .unauthenticated
        
        self.randomAuthData = generateRandom(count: 16)
    }
    
    func startAuthenticating(withScooterManager scooterManager: ScooterManager) {
        guard !self.authenticated else {
            return
        }
        
        self.authState = .start
        scooterManager.write(Data(hex: "215b00")) { self.authState == .start }
    }
    
    func continueAuthenticating(withScooterManager scooterManager: ScooterManager, received data: Data, forCharacteristic uuid: CBUUID) {
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
            self.authState = .buttonPress
            scooterManager.write(Data(hex: "215c00") + self.randomAuthData) { self.authState == .buttonPress }
        }
        
        if (src == 0x21 &&
            dst == 0x3E &&
            cmd == 0x5C) {
            self.authState = .finish
            if (arg == 0x00) {
                scooterManager.scooterBluetooth.setConnectionState(.authenticating)
            }
            scooterManager.write(Data(hex: "215d00")) { self.authState == .finish }
        }
        
        if (src == 0x21 &&
            dst == 0x3E &&
            cmd == 0x5D &&
            arg == 0x01) {
            self.authState = .authenticated
            scooterManager.scooterBluetooth.setConnectionState(.connected)
        }
    }
}
