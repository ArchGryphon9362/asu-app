//
//  ScooterBluetooth.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import Foundation
import CoreBluetooth

enum ConnectionState {
    case disconnected
    case connecting
    case ready
    case authenticating
    case connected
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .disconnected: return "dis"
        case .connecting: return "con.."
        case .ready: return "ready"
        case .authenticating: return "auth"
        case .connected: return "con!"
        }
    }
}

//extension CBCentralManager {
////    + (id) retrieveAddressForPeripheral: (id) arg0
//    func retrieveAddressForPeripheral_() -> ( (_: CBPeripheral) -> (String?) )? {
//        print(#selector(CBCentralManager.cancelPeripheralConnection))
//        let privateMethodSelector = Selector(("retrieveAddressForPeripheral:"))
//        if let privateMethod = CBCentralManager.perform(privateMethodSelector, with: self).takeUnretainedValue() as? (_: CBPeripheral) -> (String?) {
//                return privateMethod
//            }
//        return nil
//    }
//}

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
    let serviceData: Data
    
    let peripheral: CBPeripheral
    
    init(name: String, model: ScooterModel, rssi: Int, mac: String, serviceData: Data, peripheral: CBPeripheral) {
        self.name = name
        self.model = model
        self.rssi = rssi
        self.mac = mac
        self.serviceData = serviceData
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

// TODO: clear scooter list when no more bluetooth (or something) (maybe check if peripheral was invalidated or RSSI -100?)
// TODO: perhaps store current peripheral's identifier to ensure double connections can't affect the intended connection
class ScooterBluetooth : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    var bluetoothManager: CBCentralManager!
    let bluetoothQueue = DispatchQueue(label: "dev.nyaaa.asu.BLEQueue")
    var connectionState: ConnectionState
    var blockDisconnectUpdates: Bool
    
    private var scooterBluetoothDelegate: ScooterBluetoothDelegate?
    private var scooterProtocol: ScooterProtocol
    private var messageGlue: MessageGlue
    
    private var peripheral: CBPeripheral?
    private var serialWriteChar: CBCharacteristic?
    private var upnpChar: CBCharacteristic?
    private var avdtpChar: CBCharacteristic?
    
    private var writeLoop: WriteLoop
    
    override init() {
//        self.bluetoothManager = CBCentralManager()
        self.connectionState = .disconnected
        self.blockDisconnectUpdates = false
        self.scooterProtocol = .ninebot(true)
        self.messageGlue = .init(scooterProtocol: scooterProtocol, payloadSize: 20) // setting to some random crap so compiler doesn't complain
        
        self.writeLoop = .init()
        
        super.init()
        
//        self.bluetoothManager.delegate = self
        self.bluetoothManager = CBCentralManager(delegate: self, queue: self.bluetoothQueue)
    }
    
    func setConnectionState(_ connectionState: ConnectionState) {
        guard self.connectionState != connectionState else {
            return
        }
        
        self.connectionState = connectionState
        if (connectionState == .disconnected) {
            self.peripheral = nil
            self.serialWriteChar = nil
            self.upnpChar = nil
            self.avdtpChar = nil
            Task {
                await self.writeLoop.stop()
            }
        }
        DispatchQueue.main.async {
            self.scooterBluetoothDelegate?.scooterBluetoothDidUpdateState(self)
        }
    }
    
    func setScooterBluetoothDelegate(_ scooterBluetoothDelegate: ScooterBluetoothDelegate) {
        self.scooterBluetoothDelegate = scooterBluetoothDelegate
    }
    
    func connect(_ peripheral: CBPeripheral, name: String, scooterProtocol: ScooterProtocol) {
        guard bluetoothManager.state == .poweredOn else { return }
        setConnectionState(.connecting)
        self.scooterProtocol = scooterProtocol
        // save the peripheral just to be safe (because the only other place it just so happens to be saved
        // is the discovered scooter stuff, and that's just a (painfully slow) race condition waiting to
        // happen in my opinion)
        self.peripheral = peripheral
        bluetoothManager.connect(peripheral)
    }
    
    func disconnect(_ peripheral: CBPeripheral?) {
        let peripheral = peripheral ?? self.peripheral
        setConnectionState(.disconnected)
        guard bluetoothManager.state == .poweredOn, let peripheral = peripheral else { return }
        bluetoothManager.cancelPeripheralConnection(peripheral)
    }
    
    func write(writeType: WriteLoop.WriteType, characteristic: WriteLoop.WriteCharacteristic, getData: @escaping () -> (Data)) {
        guard self.connectionState != .disconnected else {
            return
        }
        Task {
            await self.writeLoop.enqueue(writeType: writeType, characteristic: characteristic, getData: getData)
        }
    }
    
    // central manager delegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        print(central.retrieveAddressForPeripheral_())
        if central.state == .poweredOn {
            let services = [xiaoAuthServiceUUID, serialServiceUUID]
            // TODO: DON'T publish use_bdaddr to App Store!!!
//            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true, "use_bdaddr": true])
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
        // TODO: DO NOT push this to app store either
        //        print(central.retrieveAddressForPeripheral(peripheral))
        //        let model = ScooterModel.XiaomiPro2(true)
        
        let serviceDataList = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: NSData] ?? [:]
        var serviceData = Data()
        if let data = serviceDataList[xiaoAuthServiceUUID] {
            serviceData = Data(data.reversed())
            if data.count >= 7 {
                let macData = serviceData[0x01...0x06]
                mac = dataToHex(data: macData).uppercased()
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 10))
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 8))
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 6))
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 4))
                mac.insert(":", at: mac.index(mac.startIndex, offsetBy: 2))
            }
        }
        
        DispatchQueue.main.async {
            self.scooterBluetoothDelegate?.scooterBluetooth(self, didDiscover: DiscoveredScooter(
                name: name,
                model: model,
                rssi: RSSI.intValue,
                mac: mac, // TODOne: check if this mac stuff is done by nb!! **Edit:** no.
                serviceData: serviceData,
                peripheral: peripheral
            ), forIdentifier: peripheral.identifier)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // save peripheral to ensure we're talking to the same one connect was called with
        self.peripheral = peripheral
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
            
            var ready: Bool {
                switch(self.scooterProtocol) {
                case .ninebot: return true
                case let .xiaomi(crypto): return crypto
                }
            }
            
            // if ninebotCrypto
            if ready {
                Task {
                    await self.writeLoop.start(serialWrite: { data in
                        guard let peripheral = self.peripheral else {
                            return
                        }
                        
                        let maxSize = peripheral.maximumWriteValueLength(for: .withoutResponse)
                        
                        if let serialWriteChar = self.serialWriteChar {
                            for chunk in data.bytes.chunked(into: maxSize) {
                                // TODO: setup a check to make sure we can do a .withResponse
                                peripheral.writeValue(Data(chunk), for: serialWriteChar, type: .withResponse)
                            }
                        }
                    }, upnpWrite: { data in
                        guard let peripheral = self.peripheral else {
                            return
                        }
                        
                        let maxSize = peripheral.maximumWriteValueLength(for: .withoutResponse)
 
                        if let upnpChar = self.upnpChar {
                            for chunk in data.bytes.chunked(into: maxSize) {
                                peripheral.writeValue(Data(chunk), for: upnpChar, type: .withoutResponse)
                            }
                        }
                    }, avdtpWrite: { data in
                        guard let peripheral = self.peripheral else {
                            return
                        }
                        
                        let maxSize = peripheral.maximumWriteValueLength(for: .withoutResponse)
                        
                        // TODO: fix avdtp withLength
                        let withLength = false
                        
                        if let avdtpChar = self.avdtpChar {
                            if withLength {
                                for (index, chunk) in data.bytes.chunked(into: maxSize - 2).enumerated() {
                                    peripheral.writeValue(Data([UInt8(index + 1), 0] + chunk), for: avdtpChar, type: .withoutResponse)
                                }
                            } else {
                                for chunk in data.bytes.chunked(into: maxSize) {
                                    peripheral.writeValue(Data(chunk), for: avdtpChar, type: .withoutResponse)
                                }
                            }
                        }
                    })
                    await self.writeLoop.ready()
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
        
        guard self.serialWriteChar != nil, self.upnpChar != nil, self.avdtpChar != nil, case let .xiaomi(crypto) = self.scooterProtocol, crypto else {
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
        DispatchQueue.main.async {
            self.scooterBluetoothDelegate?.scooterBluetooth(self, didReceive: data, forCharacteristic: characteristic.uuid)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("### ERROR!! ###")
            debugPrint(error ?? "N/A")
            print("### ------- ###")
        }
        if error == nil && characteristic.uuid == serialTXCharUUID {
            Task {
                await self.writeLoop.ready()
            }
        }
    }
}
