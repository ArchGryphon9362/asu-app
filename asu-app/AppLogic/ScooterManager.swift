//
//  ScooterManager.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation
import CoreBluetooth
import OrderedCollections
import CryptoKit

// TODO: lower min ios version to 13 or 14
class ScooterManager : ObservableObject, ScooterBluetoothDelegate {
    private var forceNbCrypto: Bool
    
    @Published var discoveredScooters: OrderedDictionary<UUID, DiscoveredScooter>
    @Published var scooter: Scooter
    @Published var scooterBluetooth: ScooterBluetooth
    var scooterCrypto: ScooterCrypto
    
    init() {
        self.forceNbCrypto = false
        self.discoveredScooters = [:]
        self.scooter = Scooter()
        self.scooterBluetooth = ScooterBluetooth()
        self.scooterCrypto = .init()
        
        self.scooterBluetooth.setScooterBluetoothDelegate(self)
    }
    
    func connectTo(discoveredScooter: DiscoveredScooter, forceNbCrypto: Bool = false) {
        let name = discoveredScooter.name
        
        scooter.model = discoveredScooter.model
        self.forceNbCrypto = forceNbCrypto
        self.scooterCrypto.setName(name)
        self.scooterCrypto.setProtocol(discoveredScooter.model.scooterProtocol(forceNbCrypto: self.forceNbCrypto))
        scooterBluetooth.connect(discoveredScooter.peripheral, name: name, scooterProtocol: discoveredScooter.model.scooterProtocol(forceNbCrypto: self.forceNbCrypto))
    }
    
    func disconnectFromScooter(updateUi: Bool) {
        self.scooterBluetooth.blockDisconnectUpdates = !updateUi
        scooterBluetooth.disconnect(nil, overrideAuthMode: updateUi)
    }
    
    func write(_ data: Data, keepTrying: @escaping () -> (Bool)) {
        switch (self.scooter.model?.scooterProtocol(forceNbCrypto: self.forceNbCrypto)) {
        case .ninebot(true):
            self.scooterBluetooth.write { serialWrite, upnpWrite, avdtpWrite in
                guard keepTrying() else {
                    return false
                }
                
                let length = UInt8((data.count - 3) & 0xff)
                
                let encryptedData = self.scooterCrypto.encrypt(Data(ninebotHeader.bytes + [length, 0x3e] + data.bytes))
                serialWrite(encryptedData)
                
                return true
            }
        case .xiaomi(true):
            self.scooterBluetooth.write { serialWrite, upnpWrite, avdtpWrite in
                guard keepTrying() else {
                    return false
                }
                
                let length = UInt8((data.count - 3) & 0xff)
                
                let encryptedData = self.scooterCrypto.encrypt(Data(xiaomiHeader.bytes + [length] + data.bytes))
                serialWrite(encryptedData)
                
                return true
            }
        case .ninebot(false):
            self.scooterBluetooth.write { serialWrite, upnpWrite, avdtpWrite in
                guard keepTrying() else {
                    return false
                }
                
                let length = UInt8((data.count - 3) & 0xff)
                
                let fullData = Data(ninebotHeader.bytes + [length, 0x3e] + data.bytes)
                serialWrite(fullData)
                
                return true
            }
        case .xiaomi(false):
            self.scooterBluetooth.write { serialWrite, upnpWrite, avdtpWrite in
                guard keepTrying() else {
                    return false
                }
                
                let length = UInt8((data.count - 3) & 0xff)
                
                let fullData = Data(xiaomiHeader.bytes + [length] + data.bytes)
                serialWrite(fullData)
                
                return true
            }
        default: return
        }
    }
    
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didDiscover scooter: DiscoveredScooter, forIdentifier: UUID) {
        if let oldScooter = self.discoveredScooters[forIdentifier] {
            if scooterCrypto.awaitingButtonPress && oldScooter.serviceData != scooter.serviceData {
                self.connectTo(discoveredScooter: scooter)
            }
        }
        
        self.discoveredScooters[forIdentifier] = scooter
    }
    
    func scooterBluetoothDidUpdateState(_ scooterBluetooth: ScooterBluetooth) {
        let connectionState = self.scooterBluetooth.connectionState
        self.scooter.connectionState = connectionState
        self.scooter.authenticating = self.scooter.authenticating || connectionState == .authenticating
        
        switch(connectionState) {
        case .disconnected:
            if !self.scooterBluetooth.blockDisconnectUpdates {
                self.scooter.reset()
                self.scooterCrypto.reset()
            }
        case .ready:
            if !self.scooterCrypto.authenticated {
                self.scooterCrypto.startAuthenticating(withScooterManager: self)
            }
        case .connected:
            // collect infos
            // TODO: cmd generator.
            self.write(Data(hex: "2001100e")) { self.scooter.serial == nil }
            self.write(Data(hex: "20011a02")) { self.scooter.esc == nil }
            self.write(Data(hex: "20016702")) { self.scooter.bms == nil }
            self.write(Data(hex: "20016802")) { self.scooter.ble == nil }
        default: return
        }
    }
    
    // TODO: make a proper handler for this stuff perhaps? or maybe a decoder class that extracts and gives all related info
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didReceive data: Data, forCharacteristic uuid: CBUUID) {
        var data = data
        if uuid == serialRXCharUUID {
            guard let decryptedData = self.scooterCrypto.decrypt(data) else {
                return
            }
            data = decryptedData
        }
        
        if !self.scooterCrypto.authenticated {
            self.scooterCrypto.continueAuthenticating(withScooterManager: self, received: data, forCharacteristic: uuid)
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
        
        if (src == 0x23 &&
            dst == 0x3E &&
            cmd == 0x01) {
            func parseVersion(_ versionMsg: [UInt8]) -> String? {
                guard versionMsg.count - 0x07 == 0x02 else { return nil }
                var ver = Data([
                    versionMsg[0x07 + 0x01],
                    versionMsg[0x07 + 0x00]
                ])
                
                let first  = (ver[0] & 0xF0) >> 4
                let second = (ver[0] & 0x0F) >> 0
                let third  = (ver[1] & 0xF0) >> 4
                let forth  = (ver[1] & 0x0F) >> 0
                
                let firstPart = first != 0 ? "\(first)." : ""
                let result = "\(second).\(third).\(forth)"
                return firstPart + result
            }
            
            switch(arg) {
            // TODO: rescan versions and serial when changed
            case 0x10:
                guard payloadLength == 0x0e else { return }
                let serial = String(data: Data(data[0x07 + 0x00...0x07 + 0x0e - 1]), encoding: .ascii)
                self.scooter.serial = serial
            case 0x1a:
                guard payloadLength == 0x02 else { return }
                guard let ver = parseVersion(data.bytes) else { return }
                self.scooter.esc = ver
            case 0x67:
                guard payloadLength == 0x02 else { return }
                guard let ver = parseVersion(data.bytes) else { return }
                self.scooter.bms = ver
            case 0x68:
                guard payloadLength == 0x02 else { return }
                guard let ver = parseVersion(data.bytes) else { return }
                self.scooter.ble = ver
            default: return
            }
        }
    }
}
