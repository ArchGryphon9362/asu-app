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

// thx: https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
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
    private var messageGlue: MessageGlue
    
    private var authTimer: Timer
    
    private func setConnectionState(_ connectionState: ConnectionState) {
        self.connectionState = connectionState
        self.scooterManager.scooter.connectionState = connectionState
    }
    
    init(_ scooterManager: ScooterManager) {
        self.scooterManager = scooterManager
        self.bluetoothManager = CBCentralManager()
        self.connectionState = .disconnected
        self.ninebotCrypto = .init()
        self.messageGlue = .init(selectedProtocol: .ninebotCrypto, payloadSize: 20) // setting to some random crap so compiler doesn't complain
        
        self.authTimer = Timer()
        
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
        self.authTimer.invalidate()
        setConnectionState(.disconnected)
        guard bluetoothManager.state == .poweredOn else { return }
        bluetoothManager.cancelPeripheralConnection(peripheral)
    }
    
    func write(_ data: Data) {
        guard let writeChar = self.writeChar, let peripheral = self.peripheral else {
            return
        }
        let maxSize = peripheral.maximumWriteValueLength(for: .withoutResponse)
        
        let length = UInt8((data.count - 4) & 0xff)
        let encryptedData = self.ninebotCrypto.Encrypt(msgHeader.bytes + [length] + data.bytes) ?? []
//        let encryptedData = Data(hex: "5aa50031de6a25000045ff0000").bytes
        print("writing \(dataToHex(data: Data(encryptedData)))")
        
        for chunk in encryptedData.chunked(into: maxSize) {
            peripheral.writeValue(Data(chunk), for: writeChar, type: .withoutResponse)
        }
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
        // TODO: set correct protocol
        self.messageGlue = .init(selectedProtocol: .ninebotCrypto, payloadSize: peripheral.maximumWriteValueLength(for: .withoutResponse))
        
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
        
        // start pairing request (repeats because xiaomi)
        self.authTimer.invalidate()
        self.authTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.write(Data(hex: "3e215b00"))
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == serialRXCharUUID else {
            // don't want foreign chars
            return
        }
        
        guard let rawMsg = characteristic.value else {
            // don't want partial raw
            return
        }
        
        guard let fullRawMsg = self.messageGlue.put(data: rawMsg.bytes) else {
            // don't want fully raw either
            return
        }
        
        guard let msg = self.ninebotCrypto.Decrypt(fullRawMsg) else {
            // cryptic isn't good either
            return
        }
        
        guard msg.count > 6 else {
            // just ignore all the invalid messages
            return
        }
        
        let src = msg[3]
        let dst = msg[4]
        let cmd = msg[5]
        let arg = msg[6]
        
        // check auth (nbauth, will need to add others later)
        if (src == 0x21 &&
            dst == 0x3E &&
            cmd == 0x5B) {
            self.authTimer.invalidate()
            self.authTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.write(Data(hex: "3e215c0000000000000000000000000000000000")) // <- final 16 bytes will be autofilled
            }
        }
        
        if (src == 0x21 &&
            dst == 0x3E &&
            cmd == 0x5C) {
            if (arg == 0x00) {
                setConnectionState(.pairing)
            }
            self.authTimer.invalidate()
            self.authTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.write(Data(hex: "3e215d00"))
            }
        }
        
        if (src == 0x21 &&
            dst == 0x3E &&
            cmd == 0x5D &&
            arg == 0x01) {
            self.authTimer.invalidate()
            setConnectionState(.connected)
            
            // TODO: list of "wants" (once satisfied a timer stop looping)
            write(Data(hex: "3e2001100e"))
        }
        
        // TODO: move this into scooter manager or sum
        if (src == 0x23 &&
            dst == 0x3E &&
            cmd == 0x01) {
            print(dataToHex(data: Data(msg)))
            switch(arg) {
            case 0x10:
                guard msg.count == 0x15 else { return }
                let serial = String(data: Data(msg[0x07...0x11]), encoding: .ascii)
                scooterManager.scooter.serial = serial
            default: return
            }
        }
        
        print(dataToHex(data: Data(msg)))
    }
}
