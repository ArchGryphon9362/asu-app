//
//  ScooterBluetooth.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import Foundation
import CoreBluetooth

enum ConnectionState {
    case disconnected
    case connecting
    case pairing
    case connected
    case disconnecting
}

class DiscoveredScooter : ObservableObject, Identifiable {
    @Published var name: String
    let model: ScooterModel
    @Published var rssi: Int
    
    let peripheral: CBPeripheral
    
    init(name: String, model: ScooterModel, rssi: Int, peripheral: CBPeripheral) {
        self.name = name
        self.model = model
        self.rssi = rssi
        self.peripheral = peripheral
    }
}

class ScooterBluetooth : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    let scooterManager: ScooterManager
    let bluetoothManager: CBCentralManager
    @Published var connectionState: ConnectionState
    
    init(_ scooterManager: ScooterManager) {
        self.scooterManager = scooterManager
        self.bluetoothManager = CBCentralManager()
        self.connectionState = .disconnected
        
        super.init()
        
        self.bluetoothManager.delegate = self
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }
        
        if let scooter = scooterManager.discoveredScooters[peripheral.identifier] {
            scooter.name = name
            scooter.rssi = RSSI.intValue
        } else {
            scooterManager.discoveredScooters[peripheral.identifier] = DiscoveredScooter(
                name: name,
                model: .XiaomiPro2, // TODO: no it isn't (at least we don't know yet)
                rssi: RSSI.intValue,
                peripheral: peripheral
            )
        }
    }
}
