//
//  ScooterManager.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation
import OrderedCollections
import CoreBluetooth

class ScooterManager : ObservableObject, ScooterBluetoothDelegate {
    class CoreInfo : Observable {
        @State fileprivate(set) var serial: String? = nil
        @State fileprivate(set) var esc: NinebotVersion? = nil
        @State fileprivate(set) var ble: NinebotVersion? = nil
        @State fileprivate(set) var bms: NinebotVersion? = nil
        
        // init code
        private var scooter: ScooterManager! = nil
        
        fileprivate func setScooter(_ scooter: ScooterManager) {
            self.scooter = scooter
        }
    }
    
    fileprivate var forceNbCrypto: Bool = false
    fileprivate var scooterBluetooth: ScooterBluetooth = .init()
    fileprivate var scooterCrypto: ScooterCrypto = .init()
    fileprivate var messageManager: RawMessageManager = .init(scooterProtocol: .ninebot(true))
    fileprivate var scooterRemover: [UUID: Timer] = [:]
    
    // used for ensuring only 1 info dump can run at any given time
    // (any more would be a waste of WriteLoop cycles)
    fileprivate var infoDumpId = 0
    
    @Published var discoveredScooters: OrderedDictionary<UUID, DiscoveredScooter> = [:]
    
    @Published var coreInfo: CoreInfo = .init()
    @Published var infoDump: StockNBMessage.InfoDump? = nil
    
    var authenticating: Bool = false
    var model: ScooterModel? = nil
    var connectionState: ConnectionState = .disconnected
    
    init() {
        self.scooterBluetooth.setScooterBluetoothDelegate(self)
        self.coreInfo.setScooter(self)
    }
    
    // basic bluetooth methods
    func connectTo(discoveredScooter: DiscoveredScooter, forceNbCrypto: Bool = false) {
        let name = discoveredScooter.name
        let scooterProtocol = discoveredScooter.model.scooterProtocol(forceNbCrypto: forceNbCrypto)
        
        self.model = discoveredScooter.model
        self.forceNbCrypto = forceNbCrypto
        self.scooterCrypto.setName(name)
        self.scooterCrypto.setProtocol(scooterProtocol)
        self.messageManager = .init(scooterProtocol: scooterProtocol)
        scooterBluetooth.connect(discoveredScooter.peripheral, name: name, scooterProtocol: scooterProtocol)
    }
    
    // TODO: add "updateUi" back for miauth
    func disconnectFromScooter() {
        scooterBluetooth.disconnect(nil)
    }
    
    func writeRaw(_ data: Data?, characteristic: WriteLoop.WriteCharacteristic, writeType: WriteLoop.WriteType) {
        guard let data = data else {
            return
        }
        
        self.scooterBluetooth.write(writeType: writeType, characteristic: characteristic) {
            var data = data
            if characteristic == .serial, self.model?.scooterProtocol(forceNbCrypto: self.forceNbCrypto).crypto == true {
                data = self.scooterCrypto.encrypt(data)
            }
            return data
        }
    }
    
    // private stuff
    fileprivate func handle(_ message: ParsedNinebotMessage) {
        // TODO: do something with the parsed data
        switch message {
        case let .stockNBMessage(message): self.handleStockNB(message)
        case let .shfwMessage(message): self.handleSHFW(message)
        default: break
        }
    }
    
    fileprivate func handleStockNB(_ message: StockNBMessage) {
        switch message {
        case let .serialNumber(serial): self.coreInfo.serial = serial
        case let .escVersion(version): self.coreInfo.esc = version
        case let .bleVersion(version): self.coreInfo.ble = version
        case let .bmsVersion(version): self.coreInfo.bms = version
        case let .infoDump(infoDump): self.infoDump = infoDump
        default: break
        }
    }
    
    fileprivate func handleSHFW(_ message: SHFWMessage) {
        
    }
    
    fileprivate func startInfoDump() {
        self.infoDumpId += 1
        let newInfoDumpId = self.infoDumpId
        let infoDumpMsg = self.messageManager.ninebotRead(StockNBMessage.infoDump())
        self.writeRaw(infoDumpMsg, characteristic: .serial, writeType: .condition {
            self.infoDumpId == newInfoDumpId
        })
    }
    
    fileprivate func stopInfoDump() {
        self.infoDumpId += 1
    }
    
    fileprivate func requestAll() {
        self.requestCoreInfo()
        self.requestFullShfw()
    }
    
    fileprivate func requestCoreInfo() {
        let coreRequests: [(NinebotMessage, PartialKeyPath<CoreInfo>)] = [
            (StockNBMessage.serialNumber(), \CoreInfo.serial),
            (StockNBMessage.escVersion(), \CoreInfo.esc),
            (StockNBMessage.bleVersion(), \CoreInfo.ble),
            (StockNBMessage.bmsVersion(), \CoreInfo.bms)
        ]
        
        for (request, key) in coreRequests {
            let msg = self.messageManager.ninebotRead(request)
            self.writeRaw(msg, characteristic: .serial, writeType: .condition(
                condition: {
                    self.coreInfo[keyPath: key] as Optional == nil
                }
            ))
        }
    }
    
    fileprivate func requestFullShfw() {
        
    }
    
    // underlying ScooterBluetooth methods
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didDiscover scooter: DiscoveredScooter, forIdentifier identifier: UUID) {
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
        self.connectionState = connectionState
        self.authenticating = self.authenticating || connectionState == .authenticating
        
        switch(connectionState) {
        case .disconnected:
            if !self.scooterBluetooth.blockDisconnectUpdates {
                self.authenticating = false
                self.model = nil
                self.connectionState = .disconnected
                
                self.scooterCrypto.reset()
            }
        case .ready:
            if !self.scooterCrypto.authenticated {
                self.scooterCrypto.startAuthenticating(withScooterManager: self)
            }
        case .connected:
            // TODO: start collecting info and whatnot
            self.startInfoDump()
            self.requestAll()
        default: return
        }
    }
    
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didReceive data: Data, forCharacteristic uuid: CBUUID) {
        var data = data
        if uuid == serialRXCharUUID {
            guard let decryptedData = self.scooterCrypto.decrypt(data) else {
                return
            }
            data = decryptedData
        }
        
        if !self.scooterCrypto.authenticated {
            let connectionState = self.scooterCrypto.continueAuthenticating(withScooterManager: self, received: data, forCharacteristic: uuid)
            if let connectionState = connectionState {
                scooterBluetooth.setConnectionState(connectionState)
            }
            return
        }
        
        if let parsedData = self.messageManager.ninebotParse(data) {
            self.handle(parsedData)
        }
    }
}

