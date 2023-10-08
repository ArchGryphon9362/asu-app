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
    case ready
    case pairing
    case connected
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .disconnected: return "dis"
        case .connecting: return "con.."
        case .ready: return "ready"
        case .pairing: return "pair"
        case .connected: return "con!"
        }
    }
}

protocol ScooterBluetoothDelegate {
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didDiscover scooter: DiscoveredScooter, forIdentifier: UUID)
    func scooterBluetoothDidUpdateState(_ scooterBluetooth: ScooterBluetooth)
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didReceive data: Data, forCharacteristic uuid: CBUUID)
}

class DiscoveredScooter : ObservableObject, Identifiable, Hashable {
    @Published var name: String
    let model: ScooterModel
    @Published var rssi: Int
    let mac: String
    
    let peripheral: CBPeripheral
    
    init(name: String, model: ScooterModel, rssi: Int, mac: String, peripheral: CBPeripheral) {
        self.name = name
        self.model = model
        self.rssi = rssi
        self.mac = mac
        self.peripheral = peripheral
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral)
    }

    static func == (lhs: DiscoveredScooter, rhs: DiscoveredScooter) -> Bool {
        return lhs.name        == rhs.name &&
               lhs.model       == rhs.model &&
               lhs.rssi        == rhs.rssi &&
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
// TODO: perhaps store current peripheral's identifier to ensure double connections can't affect the intended connection
class ScooterBluetooth : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    let bluetoothManager: CBCentralManager
    var connectionState: ConnectionState
    
    private var scooterBluetoothDelegate: ScooterBluetoothDelegate?
    private var scooterProtocol: ScooterProtocol
    private var messageGlue: MessageGlue
    
    private var peripheral: CBPeripheral?
    private var serialWriteChar: CBCharacteristic?
    private var upnpChar: CBCharacteristic?
    private var avdtpChar: CBCharacteristic?
    
    private var writeScheduler: Timer
    private var scheduledWrites: [(_ serialWrite: (Data) -> (), _ upnpWrite: (Data) -> (), _ avdtpWrite: (Data) -> ()) -> (Bool)]
    
    private func writeLoop() {
        guard let peripheral = self.peripheral else {
            return
        }
        
        let maxSize = peripheral.maximumWriteValueLength(for: .withoutResponse)
        
        var tempScheduledWrites: [(_ serialWrite: (Data) -> (), _ upnpWrite: (Data) -> (), _ avdtpWrite: (Data) -> ()) -> (Bool)] = []
        for scheduledWrite in self.scheduledWrites {
            let keepWriting = scheduledWrite({ data in
                if let serialWriteChar = self.serialWriteChar {
                    for chunk in data.bytes.chunked(into: maxSize) {
                        peripheral.writeValue(Data(chunk), for: serialWriteChar, type: .withoutResponse)
                    }
                }
            }, { data in
                if let upnpChar = self.upnpChar {
                    for chunk in data.bytes.chunked(into: maxSize) {
                        peripheral.writeValue(Data(chunk), for: upnpChar, type: .withoutResponse)
                    }
                }
            }, { data in
                if let avdtpChar = self.avdtpChar {
                    for chunk in data.bytes.chunked(into: maxSize) {
                        peripheral.writeValue(Data(chunk), for: avdtpChar, type: .withoutResponse)
                    }
                }
            })
            if keepWriting {
                tempScheduledWrites.append(scheduledWrite)
            }
        }
        self.scheduledWrites = tempScheduledWrites
    }
    
    override init() {
        self.bluetoothManager = CBCentralManager()
        self.connectionState = .disconnected
        self.scooterProtocol = .ninebot(true)
        self.messageGlue = .init(scooterProtocol: scooterProtocol, payloadSize: 20) // setting to some random crap so compiler doesn't complain
        
        self.writeScheduler = Timer()
        self.scheduledWrites = []
        
        super.init()
        
        self.bluetoothManager.delegate = self
    }
    
    func setConnectionState(_ connectionState: ConnectionState) {
        guard self.connectionState != connectionState else {
            return
        }
        
        self.connectionState = connectionState
        self.scooterBluetoothDelegate?.scooterBluetoothDidUpdateState(self)
        if (connectionState == .disconnected) {
            self.peripheral = nil
            self.serialWriteChar = nil
            self.upnpChar = nil
            self.avdtpChar = nil
            self.writeScheduler.invalidate()
            self.scheduledWrites = []
        }
    }
    
    func setScooterBluetoothDelegate(_ scooterBluetoothDelegate: ScooterBluetoothDelegate) {
        self.scooterBluetoothDelegate = scooterBluetoothDelegate
    }
    
    func connect(_ peripheral: CBPeripheral, name: String, scooterProtocol: ScooterProtocol) {
        guard bluetoothManager.state == .poweredOn else { return }
        setConnectionState(.connecting)
        self.scooterProtocol = scooterProtocol
        bluetoothManager.connect(peripheral)
    }
    
    func disconnect(_ peripheral: CBPeripheral) {
        setConnectionState(.disconnected)
        guard bluetoothManager.state == .poweredOn else { return }
        bluetoothManager.cancelPeripheralConnection(peripheral)
    }
    
    func write(writeLoop: @escaping (_ serialWrite: (Data) -> (), _ upnpWrite: (Data) -> (), _ avdtpWrite: (Data) -> ()) -> (Bool)) {
        guard self.connectionState != .disconnected else {
            return
        }
        self.scheduledWrites.append(writeLoop)
    }
    
    // central manager delegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            let services = [xiaoAuthServiceUUID, serialServiceUUID]
            central.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        } else {
            setConnectionState(.disconnected)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "" // weird asf if no name but :shrug:
        
        var mac = ""
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return // unsupported
        }
        guard let model = ScooterModel.fromAdvertisement(manufactuerData: manufacturerData) else {
            print(dataToHex(data: manufacturerData))
            return // unsupported
        }
        
        let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: NSData] ?? [:]
        if serviceData.count >= 1 {
            let data = Data(Array(serviceData.values)[0].reversed())
            if data.count >= 7 {
                let macData = data[0x01...0x06]
                mac = dataToHex(data: macData).uppercased()
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 10))
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 8))
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 6))
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 4))
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 2))
            }
        }
        
        scooterBluetoothDelegate?.scooterBluetooth(self, didDiscover: DiscoveredScooter(
            name: name,
            model: model, // TODO: no it isn't (at least we don't know yet)
            rssi: RSSI.intValue,
            mac: mac, // TODO: check if this mac stuff is done by nb!!
            peripheral: peripheral
        ), forIdentifier: peripheral.identifier)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.messageGlue = .init(scooterProtocol: self.scooterProtocol, payloadSize: peripheral.maximumWriteValueLength(for: .withoutResponse))
        
        peripheral.delegate = self
        
        let services = [serialServiceUUID, xiaoAuthServiceUUID]
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
        var xiaoAuthService: CBService?
        for service in services {
            if service.uuid == serialServiceUUID {
                serialService = service
            }
            if service.uuid == xiaoAuthServiceUUID {
                xiaoAuthService = service
            }
        }
        
        guard let serialService = serialService else {
            disconnect(peripheral)
            return
        }
        
        if let xiaoAuthService = xiaoAuthService {
            let xiaoAuthChars = [xiaoUPNPCharUUID, xiaoAVDTPCharUUID]
            peripheral.discoverCharacteristics(xiaoAuthChars, for: xiaoAuthService)
        } else if case let .xiaomi(crypto) = self.scooterProtocol, crypto {
            print("Missing Xiaomi auth services!!") // TODO: fallback to nbauth??
            disconnect(peripheral)
            return
        }
        
        let serialChars = [serialRXCharUUID, serialTXCharUUID]
        peripheral.discoverCharacteristics(serialChars, for: serialService)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        switch(service.uuid) {
        case serialServiceUUID:
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
            self.serialWriteChar = txChar
            self.peripheral = peripheral
            
            var ready: Bool {
                switch(self.scooterProtocol) {
                case .ninebot: return true
                case let .xiaomi(crypto): return crypto
                }
            }
            
            // if ninebotCrypto
            if ready {
                self.writeScheduler.invalidate()
                self.writeScheduler = Timer.scheduledTimer(withTimeInterval: messageFrequency, repeats: true) { _ in
                    self.writeLoop()
                }
                setConnectionState(.ready)
            }
        case xiaoAuthServiceUUID:
            guard case let .xiaomi(crypto) = self.scooterProtocol, crypto else {
                return
            }
            
            guard let chars = service.characteristics else {
                return
            }
            
            var upnpChar: CBCharacteristic?
            var avdtpChar: CBCharacteristic?
            
            for char in chars {
                if char.uuid == xiaoUPNPCharUUID {
                    upnpChar = char
                }
                if char.uuid == xiaoAVDTPCharUUID {
                    avdtpChar = char
                }
            }
            
            guard let upnpChar = upnpChar, let avdtpChar = avdtpChar else {
                disconnect(peripheral)
                return
            }
            
            peripheral.setNotifyValue(true, for: upnpChar)
            peripheral.setNotifyValue(true, for: avdtpChar)
            
            self.upnpChar = upnpChar
            self.avdtpChar = avdtpChar
        default: break
        }
        
        guard self.serialWriteChar != nil, let upnpChar = self.upnpChar, self.avdtpChar != nil, case let .xiaomi(crypto) = self.scooterProtocol, crypto else {
            return
        }
        setConnectionState(.ready)
//        peripheral.writeValue(Data(hex: "A4"), for: upnpChar, type: .withoutResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard var data = characteristic.value else {
            return
        }
        if (characteristic.uuid == serialRXCharUUID) {
            guard let stitchedData = self.messageGlue.put(data: data.bytes) else {
                return
            }
            data = Data(stitchedData)
        }
        self.scooterBluetoothDelegate?.scooterBluetooth(self, didReceive: data, forCharacteristic: characteristic.uuid)
    }
}
