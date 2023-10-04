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
    private var selectedProtocol: SelectedProtocol
    private var ninebotCrypto: NinebotCrypto
    private var xiaomiCrypto: XiaomiCrypto
    private var messageGlue: MessageGlue
    
    private var upnpChar: CBCharacteristic?
    private var avdtpChar: CBCharacteristic?
    
    private var requestScheduler: Timer
    
    private func setConnectionState(_ connectionState: ConnectionState) {
        self.connectionState = connectionState
        self.scooterManager.scooter.connectionState = connectionState
        if (connectionState == .disconnected) {
            self.scooterManager.scooter.reset()
            self.writeChar = nil
            self.peripheral = nil
            self.ninebotCrypto.Reset()
            self.upnpChar = nil
            self.avdtpChar = nil
            self.requestScheduler.invalidate()
        }
    }
    
    init(_ scooterManager: ScooterManager) {
        self.scooterManager = scooterManager
        self.bluetoothManager = CBCentralManager()
        self.connectionState = .disconnected
        self.selectedProtocol = .ninebotCrypto
        self.ninebotCrypto = .init()
        self.ninebotCrypto.Reset()
        self.xiaomiCrypto = .init()
        self.messageGlue = .init(selectedProtocol: selectedProtocol, payloadSize: 20) // setting to some random crap so compiler doesn't complain
        
        self.requestScheduler = Timer()
        
        super.init()
        
        self.bluetoothManager.delegate = self
    }
    
    func connect(_ peripheral: CBPeripheral, name: String, selectedProtocol: SelectedProtocol) {
        guard bluetoothManager.state == .poweredOn else { return }
        self.ninebotCrypto.SetName(name)
        setConnectionState(.connecting)
        self.selectedProtocol = selectedProtocol
        bluetoothManager.connect(peripheral)
    }
    
    func disconnect(_ peripheral: CBPeripheral) {
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
        
        switch(selectedProtocol) {
        case .ninebotCrypto:
            let encryptedData = self.ninebotCrypto.Encrypt(ninebotHeader.bytes + [length] + data.bytes) ?? []
            
            for chunk in encryptedData.chunked(into: maxSize) {
                peripheral.writeValue(Data(chunk), for: writeChar, type: .withoutResponse)
            }
        case .xiaomiCrypto:
            print("oh fuck, we can't write")
            return
        default:
            return
        }
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
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }
        
        var mac = ""
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
        
        scooterManager.discoveredScooters[peripheral.identifier] = DiscoveredScooter(
            name: name,
            model: .XiaomiPro2, // TODO: no it isn't (at least we don't know yet)
            rssi: RSSI.intValue,
            mac: mac, // TODO: check if this mac stuff is done by nb!!
            peripheral: peripheral
        )
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        setConnectionState(.preparing)
        self.messageGlue = .init(selectedProtocol: self.selectedProtocol, payloadSize: peripheral.maximumWriteValueLength(for: .withoutResponse))
        
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
        } else if self.selectedProtocol == .xiaomiCrypto {
            print("Missing Xiaomi auth services")
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
            self.writeChar = txChar
            self.peripheral = peripheral
            
            if (self.selectedProtocol == .ninebotCrypto) {
                self.requestScheduler.invalidate()
                self.requestScheduler = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    self.write(Data(hex: "3e215b00"))
                }
            }
        case xiaoAuthServiceUUID:
            guard self.selectedProtocol == .xiaomiCrypto else {
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
        
        guard self.writeChar != nil, let upnpChar = self.upnpChar, self.avdtpChar != nil, self.selectedProtocol == .xiaomi else {
            return
        }
        peripheral.writeValue(Data(hex: "A4"), for: upnpChar, type: .withoutResponse)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch(characteristic.uuid) {
        case serialRXCharUUID:
            guard let rawMsg = characteristic.value else {
                // don't want partial raw
                return
            }
            
            guard let fullRawMsg = self.messageGlue.put(data: rawMsg.bytes) else {
                // don't want fully raw either
                return
            }
            
            switch (selectedProtocol) {
            case .ninebotCrypto:
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
                let payloadLength = msg.count - 0x07
                
                // do auth (nbauth, will need to add others later)
                if (src == 0x21 &&
                    dst == 0x3E &&
                    cmd == 0x5B) {
                    self.requestScheduler.invalidate()
                    self.requestScheduler = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                        self.write(Data(hex: "3e215c0000000000000000000000000000000000")) // <- final 16 bytes will be autofilled
                    }
                }
                
                if (src == 0x21 &&
                    dst == 0x3E &&
                    cmd == 0x5C) {
                    if (arg == 0x00) {
                        setConnectionState(.pairing)
                    }
                    self.requestScheduler.invalidate()
                    self.requestScheduler = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                        self.write(Data(hex: "3e215d00"))
                    }
                }
                
                if (src == 0x21 &&
                    dst == 0x3E &&
                    cmd == 0x5D &&
                    arg == 0x01) {
                    self.requestScheduler.invalidate()
                    setConnectionState(.connected)
                    
                    // TODO: list of "wants" (once satisfied a timer stop looping)
                    self.requestScheduler = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                        let scooter = self.scooterManager.scooter
                        
                        if scooter?.serial == nil {
                            self.write(Data(hex: "3e2001100e"))
                        }
                        
                        if scooter?.esc == nil {
                            self.write(Data(hex: "3e20011a02"))
                        }
                        
                        if scooter?.bms == nil {
                            self.write(Data(hex: "3e20016702"))
                        }
                        
                        if scooter?.ble == nil {
                            self.write(Data(hex: "3e20016802"))
                        }
                    }
                }
                
                self.scooterManager.onRecv(msg: msg, src: src, dst: dst, cmd: cmd, arg: arg, payloadLength: payloadLength)
            case .xiaomiCrypto:
                print("oh boy oh fuck :/")
                self.disconnect(peripheral)
            default:
                print("weird fuckery")
                self.disconnect(peripheral)
            }
        case xiaoAVDTPCharUUID:
            print(dataToHex(data: characteristic.value ?? Data()))
        default: break
        }
    }
}
