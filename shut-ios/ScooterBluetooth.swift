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
    case preparing
    case pairing
    case connected
    case disconnecting
}

class ScooterBluetooth : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    let scooterManager: ScooterManager
    let bluetoothManager: CBCentralManager
    @Published var connectionState: ConnectionState
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    init(_ scooterManager: ScooterManager) {
        self.scooterManager = scooterManager
        self.bluetoothManager = CBCentralManager()
        self.connectionState = .disconnected
        
        super.init()
    }
}
