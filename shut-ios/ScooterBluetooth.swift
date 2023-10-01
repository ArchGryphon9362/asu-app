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

// TODO: clear scooter list when no more bluetooth (or something)
// TODO: perhaps store current peripherals identifier to ensure double connections can't affect the intended connection
class ScooterBluetooth : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    let scooterManager: ScooterManager
    let bluetoothManager: CBCentralManager
    @Published var connectionState: ConnectionState
    
    private var writeChar: CBCharacteristic?
    private var peripheral: CBPeripheral?
    private var ninebotCrypto: NinebotCrypto
    
    private func setConnectionState(_ connectionState: ConnectionState) {
        self.connectionState = connectionState
        self.scooterManager.scooter.connectionState = connectionState
    }
    
    init(_ scooterManager: ScooterManager) {
        self.scooterManager = scooterManager
        self.bluetoothManager = CBCentralManager()
        self.connectionState = .disconnected
        self.ninebotCrypto = .init()
        
        super.init()
        
        self.bluetoothManager.delegate = self
    }
    
    func connect(_ peripheral: CBPeripheral, name: String) {
        guard bluetoothManager.state == .poweredOn else { return }
        self.ninebotCrypto.SetName(name)
        setConnectionState(.connecting)
        bluetoothManager.connect(peripheral)
    }
    
    func disconnect(_ peripheral: CBPeripheral) {
        self.writeChar = nil
        self.peripheral = nil
        self.ninebotCrypto.Reset()
        setConnectionState(.disconnected)
        guard bluetoothManager.state == .poweredOn else { return }
        bluetoothManager.cancelPeripheralConnection(peripheral)
    }
    
    func write(_ data: Data) {
        guard let writeChar = self.writeChar, let peripheral = self.peripheral else {
            return
        }
        
        let encryptedData = self.ninebotCrypto.Encrypt(data.bytes)
        print("sending \(encryptedData)")
        peripheral.writeValue(Data(encryptedData ?? []), for: writeChar, type: .withoutResponse)
    }
    
    // central manager delegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            let services = [discoveryServiceUUID]
            central.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
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
        
        peripheral.delegate = self
        
        let services = [serialServiceUUID]
        peripheral.discoverServices(services)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        setConnectionState(.disconnected)
    }
    
    // peripheral delegate methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            disconnect(peripheral)
            return
        }
        
        var serialService: CBService?
        for service in services {
            if service.uuid == serialServiceUUID {
                serialService = service
                break
            }
        }
        
        guard let serialService = serialService else {
            disconnect(peripheral)
            return
        }
        
        let chars = [serialRXCharUUID, serialTXCharUUID]
        peripheral.discoverCharacteristics(chars, for: serialService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard service.uuid == serialServiceUUID else {
            return
        }
        
        guard let chars = service.characteristics else {
            return
        }
        
        var rxChar: CBCharacteristic?
        var txChar: CBCharacteristic?
        
        for char in chars {
            if char.uuid == serialRXCharUUID {
                rxChar = char
            }
            if char.uuid == serialTXCharUUID {
                txChar = char
            }
        }
        
        guard let rxChar = rxChar, let txChar = txChar else {
            disconnect(peripheral)
            return
        }
        
        peripheral.setNotifyValue(true, for: rxChar)
        self.writeChar = txChar
        self.peripheral = peripheral
        
        // write starting data
        write(Data(hex: "5aa53e215b00"))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("e.")
        guard characteristic.uuid == serialRXCharUUID else {
            return
        }
        
        print(characteristic.value)
    }
}
