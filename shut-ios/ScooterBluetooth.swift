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
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .disconnected: return "dis"
        case .connecting: return "con.."
        case .preparing: return "prep"
        case .pairing: return "pair"
        case .connected: return "con!"
        }
    }
}

class DiscoveredScooter : ObservableObject, Identifiable, Hashable {
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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral)
    }

    static func == (lhs: DiscoveredScooter, rhs: DiscoveredScooter) -> Bool {
        return lhs.name  == rhs.name &&
               lhs.model == rhs.model &&
               lhs.rssi  == rhs.rssi &&
               lhs.peripheral  == rhs.peripheral
    }
}

// TODO: clear scooter list when no more bluetooth
// TODO: perhaps store current peripherals identifier to ensure double connections can't affect the intended connection
class ScooterBluetooth : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    let scooterManager: ScooterManager
    let bluetoothManager: CBCentralManager
    @Published var connectionState: ConnectionState
    
    private func setConnectionState(_ connectionState: ConnectionState) {
        self.connectionState = connectionState
        self.scooterManager.scooter.connectionState = connectionState
    }
    
    init(_ scooterManager: ScooterManager) {
        self.scooterManager = scooterManager
        self.bluetoothManager = CBCentralManager()
        self.connectionState = .disconnected
        
        super.init()
        
        self.bluetoothManager.delegate = self
    }
    
    func connect(_ peripheral: CBPeripheral) {
        guard bluetoothManager.state == .poweredOn else { return }
        setConnectionState(.connecting)
        bluetoothManager.connect(peripheral)
    }
    
    func disconnect(_ peripheral: CBPeripheral) {
        guard bluetoothManager.state == .poweredOn else { return }
        bluetoothManager.cancelPeripheralConnection(peripheral)
        setConnectionState(.disconnected)
    }
    
    // central manager delegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil)
        } else {
            setConnectionState(.disconnected)
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
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        setConnectionState(.preparing)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        setConnectionState(.disconnected)
    }
    
    // peripheral delegate methods
}
