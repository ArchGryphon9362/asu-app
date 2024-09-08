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
    var messageManager: MessageManager
    var scooterRemover: [UUID: Timer]
    
    init() {
        self.forceNbCrypto = false
        self.discoveredScooters = [:]
        self.scooter = Scooter()
        self.scooterBluetooth = ScooterBluetooth()
        self.scooterCrypto = .init()
        self.messageManager = .init(scooterProtocol: .ninebot(true))
        self.scooterRemover = [:]
        
        self.scooterBluetooth.setScooterBluetoothDelegate(self)
    }
    
    func connectTo(discoveredScooter: DiscoveredScooter, forceNbCrypto: Bool = false) {
        let name = discoveredScooter.name
        let scooterProtocol = discoveredScooter.model.scooterProtocol(forceNbCrypto: self.forceNbCrypto)
        
        scooter.model = discoveredScooter.model
        self.forceNbCrypto = forceNbCrypto
        self.scooterCrypto.setName(name)
        self.scooterCrypto.setProtocol(scooterProtocol)
        self.messageManager = .init(scooterProtocol: scooterProtocol)
        scooterBluetooth.connect(discoveredScooter.peripheral, name: name, scooterProtocol: scooterProtocol)
    }
    
    func disconnectFromScooter(updateUi: Bool) {
        self.scooterBluetooth.blockDisconnectUpdates = !updateUi
        scooterBluetooth.disconnect(nil, overrideAuthMode: updateUi)
    }
    
    func write(_ data: Data?, keepTrying: @escaping () -> (Bool)) {
        guard let data = data else {
            return
        }
        
        switch (self.scooter.model?.scooterProtocol(forceNbCrypto: self.forceNbCrypto).crypto) {
        case true:
            self.scooterBluetooth.write(writeType: .condition(condition: keepTrying), characteristic: .serial) {
                let encryptedData = self.scooterCrypto.encrypt(data)
                return encryptedData
            }
        case false:
            self.scooterBluetooth.write(writeType: .condition(condition: keepTrying), characteristic: .serial) {
                return data
            }
        default: return
        }
    }
    
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didDiscover scooter: DiscoveredScooter, forIdentifier identifier: UUID) {
//        if let _ = self.discoveredScooters[forIdentifier] {
//            return
//        }
        if let oldScooter = self.discoveredScooters[identifier] {
            if scooterCrypto.awaitingButtonPress && oldScooter.serviceData != scooter.serviceData {
                self.connectTo(discoveredScooter: scooter)
            }
        }
        
        self.discoveredScooters[identifier] = scooter
        self.scooterRemover[identifier]?.invalidate()
        self.scooterRemover[identifier] = Timer.scheduledTimer(withTimeInterval: advertisementTimeout, repeats: false) { _ in
            self.discoveredScooters.removeValue(forKey: identifier)
        }
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
            self.write(self.messageManager.ninebotRead(StockNBMessage.serialNumber())) { self.scooter.serial == nil }
            self.write(self.messageManager.ninebotRead(StockNBMessage.escVersion())) { self.scooter.esc == nil }
            self.write(self.messageManager.ninebotRead(StockNBMessage.bmsVersion())) { self.scooter.bms == nil }
            self.write(self.messageManager.ninebotRead(StockNBMessage.bleVersion())) { self.scooter.ble == nil }
            self.write(self.messageManager.ninebotRead(StockNBMessage.infoDump())) { true }
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
        
        let parsedData = self.messageManager.ninebotParse(data)
        switch parsedData {
        case let .stockNBMessage(ninebotMessage):
            switch ninebotMessage {
            case let .serialNumber(serial): self.scooter.serial = serial
            case let .escVersion(version): self.scooter.esc = version.parsed
            case let .bmsVersion(version): self.scooter.bms = version.parsed
            case let .bleVersion(version): self.scooter.ble = version.parsed
            case let .infoDump(infoDump): self.scooter.infoDump = infoDump
            default: break
            }
        default: break
        }
        
//        guard data.count > 6 else {
//            return
//        }
//        
//        let payloadLength = data[2 + 0x00]
//        let src = data[2 + 0x01]
//        let dst = data[2 + 0x02]
//        let cmd = data[2 + 0x03]
//        let arg = data[2 + 0x04]
//        
//        guard data.count - 0x07 >= payloadLength else {
//            return
//        }
//        
//        if (src == 0x23 &&
//            dst == 0x3E &&
//            cmd == 0x01) {
//            func parseVersion(_ versionMsg: [UInt8]) -> String? {
//                guard versionMsg.count - 0x07 == 0x02 else { return nil }
//                var ver = Data([
//                    versionMsg[0x07 + 0x01],
//                    versionMsg[0x07 + 0x00]
//                ])
//                
//                let first  = (ver[0] & 0xF0) >> 4
//                let second = (ver[0] & 0x0F) >> 0
//                let third  = (ver[1] & 0xF0) >> 4
//                let forth  = (ver[1] & 0x0F) >> 0
//                
//                let firstPart = first != 0 ? "\(first)." : ""
//                let result = "\(second).\(third).\(forth)"
//                return firstPart + result
//            }
//            
//            switch(arg) {
//            // TODO: rescan versions and serial when changed
//            case 0x10:
//                guard payloadLength == 0x0e else { return }
//                let serial = String(data: Data(data[0x07 + 0x00...0x07 + 0x0e - 1]), encoding: .ascii)
//                self.scooter.serial = serial
//            case 0x1a:
//                guard payloadLength == 0x02 else { return }
//                guard let ver = parseVersion(data.bytes) else { return }
//                self.scooter.esc = ver
//            case 0x67:
//                guard payloadLength == 0x02 else { return }
//                guard let ver = parseVersion(data.bytes) else { return }
//                self.scooter.bms = ver
//            case 0x68:
//                guard payloadLength == 0x02 else { return }
//                guard let ver = parseVersion(data.bytes) else { return }
//                self.scooter.ble = ver
//            default: return
//            }
//        }
    }
}
