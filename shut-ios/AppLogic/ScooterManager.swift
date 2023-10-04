//
//  ScooterManager.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation
import OrderedCollections

class ScooterManager : ObservableObject {
    @Published var discoveredScooters: OrderedDictionary<UUID, DiscoveredScooter>
    // I, Lex, solely acknowledge that my initializing method can be classed as "fucking unsafe",
    // I will proceed with care. :trollface:
    @Published var scooter: Scooter!
    @Published var scooterBluetooth: ScooterBluetooth!
    
    init() {
        self.discoveredScooters = [:]
        self.scooter = Scooter(self)
        self.scooterBluetooth = ScooterBluetooth(self)
    }
    
    func connectToScooter(discoveredScooter: DiscoveredScooter) {
        var name = discoveredScooter.name
        if name.count < 12 {
            name = discoveredScooter.name.padding(toLength: 12, withPad: "\0", startingAt: 0)
        }
        
        scooter.model = discoveredScooter.model
        scooterBluetooth.connect(discoveredScooter.peripheral, name: name, selectedProtocol: discoveredScooter.model.auth)
    }
    
    func disconnectFromScooter(scooter: DiscoveredScooter) {
        scooterBluetooth.disconnect(scooter.peripheral)
    }
    
    func onRecv(msg: [UInt8], src: UInt8, dst: UInt8, cmd: UInt8, arg: UInt8, payloadLength: Int) {
        if (src == 0x23 &&
            dst == 0x3E &&
            cmd == 0x01) {
            func parseVersion(_ versionMsg: [UInt8]) -> String? {
                guard versionMsg.count - 0x07 == 0x02 else { return nil }
                var ver = dataToHex(data:
                    Data(
                        [
                            versionMsg[0x07 + 0x01],
                            versionMsg[0x07 + 0x00]
                        ]
                    )
                )
                ver = String(String(ver.reversed()).padding(toLength: 3, withPad: "0", startingAt: 0).reversed()) // remove/add from/to beginning to reach length of 3
                ver.insert(".", at: ver.index(ver.startIndex, offsetBy: 2))
                ver.insert(".", at: ver.index(ver.startIndex, offsetBy: 1))
                return ver
            }
            
            switch(arg) {
            // TODO: rescan versions and serial when changed
            case 0x10:
                guard payloadLength == 0x0e else { return }
                let serial = String(data: Data(msg[0x07 + 0x00...0x07 + 0x0e - 1]), encoding: .ascii)
                self.scooter.serial = serial
            case 0x1a:
                guard payloadLength == 0x02 else { return }
                guard let ver = parseVersion(msg) else { return }
                self.scooter.esc = ver
            case 0x67:
                guard payloadLength == 0x02 else { return }
                guard let ver = parseVersion(msg) else { return }
                self.scooter.bms = ver
            case 0x68:
                guard payloadLength == 0x02 else { return }
                guard let ver = parseVersion(msg) else { return }
                self.scooter.ble = ver
            default: return
            }
        }
    }
}
