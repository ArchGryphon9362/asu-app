// Thanks to Basse for providing the beacon parsing code and all the models
//
//  Scooter.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation

enum ScooterModel : Equatable {
    case XiaomiM365(Bool)
    case NinebotESx(Bool)
    case XiaomiPro(Bool)
    case NinebotAirT15(Bool)
    case NinebotMaxG30(Bool)
    case NinebotMaxG65(Bool)
    case NinebotMaxG2(Bool)
    case NinebotE(Bool)
    case NinebotE2(Bool)
    case Xiaomi1S(Bool)
    case XiaomiPro2(Bool)
    case XiaomiLite(Bool)
    case Xiaomi3(Bool)
    case NinebotF2(Bool)
    case NinebotF(Bool)
    case NinebotGT1(Bool)
    case NinebotGT2(Bool)
    case NinebotF65(Bool)
    case NinebotD28(Bool)
    case NinebotD38(Bool)
    case NinebotD18(Bool)
    case NinebotP65(Bool)
    case NinebotP100(Bool)
    case NinebotX160(Bool)
    
    var image: ImageResource {
        switch(self) {
        case .XiaomiM365: return .xiaomiM365
        case .NinebotESx: return .ninebotESx
        case .XiaomiPro: return .xiaomiPro
        case .NinebotAirT15: return .ninebotAirT15
        case .NinebotMaxG30: return .ninebotMaxG30
        case .NinebotMaxG65: return .ninebotMaxG65
        case .NinebotMaxG2: return .ninebotMaxG65
        case .NinebotE: return .ninebotE
        case .NinebotE2: return .ninebotE2
        case .Xiaomi1S: return .xiaomi1S
        case .XiaomiPro2: return .xiaomiPro2
        case .XiaomiLite: return .xiaomi1S
        case .Xiaomi3: return .xiaomi3
        case .NinebotF2: return .ninebotF
        case .NinebotF: return .ninebotF
        case .NinebotGT1: return .ninebotGT2
        case .NinebotGT2: return .ninebotGT2
        case .NinebotF65: return .ninebotF
        case .NinebotD28: return .ninebotD
        case .NinebotD38: return .ninebotD
        case .NinebotD18: return .ninebotD
        case .NinebotP65: return .ninebotP65
        case .NinebotP100: return .ninebotP100
        case .NinebotX160: return .ninebotX160

        }
    }
    
    var name: String {
        switch(self) {
        case .XiaomiM365:       return "Xiaomi M365"
        case .NinebotESx:       return "Ninebot ESx"
        case .XiaomiPro:        return "Mi Electric Scooter Pro"
        case .NinebotAirT15:    return "Ninebot Air T15"
        case .NinebotMaxG30:    return "Ninebot Max (G30)"
        case .NinebotMaxG65:    return "Ninebot Max (G65)"
        case .NinebotMaxG2:     return "Ninebot Max (G2)"
        case .NinebotE:         return "Ninebot E"
        case .NinebotE2:        return "Ninebot E2"
        case .Xiaomi1S:         return "Mi Electric Scooter 1S"
        case .XiaomiPro2:       return "Mi Electric Scooter Pro 2"
        case .XiaomiLite:       return "Mi Electric Scooter Essential"
        case .Xiaomi3:          return "Mi Electric Scooter 3"
        case .NinebotF2:        return "Ninebot F2"
        case .NinebotF:         return "Ninebot F"
        case .NinebotF65:       return "Ninebot F65"
        case .NinebotGT1:       return "Ninebot GT1"
        case .NinebotGT2:       return "Ninebot GT2"
        case .NinebotD28:       return "Ninebot D28"
        case .NinebotD38:       return "Ninebot D38"
        case .NinebotD18:       return "Ninebot D18"
        case .NinebotP65:       return "Ninebot P65"
        case .NinebotP100:      return "Ninebot P100"
        case .NinebotX160:      return "Ninebot X160"
        }
    }
    
    var shortCode: String {
        switch(self) {
        case .XiaomiM365:       return "m365"
        case .NinebotESx:       return "esx"
        case .XiaomiPro:        return "pro"
        case .NinebotAirT15:    return "t15"
        case .NinebotMaxG30:    return "max"
        case .NinebotMaxG65:    return "g65"
        case .NinebotMaxG2:     return "g2"
        case .NinebotE:         return "e"
        case .NinebotE2:        return "e2"
        case .Xiaomi1S:         return "1s"
        case .XiaomiPro2:       return "pro2"
        case .XiaomiLite:       return "lite"
        case .Xiaomi3:          return "mi3"
        case .NinebotF2:        return "f2"
        case .NinebotF:         return "f"
        case .NinebotF65:       return "f65"
        case .NinebotGT1:       return "gt1"
        case .NinebotGT2:       return "gt2"
        case .NinebotD28:       return "d28"
        case .NinebotD38:       return "d38"
        case .NinebotD18:       return "d18"
        case .NinebotP65:       return "p65"
        case .NinebotP100:      return "p100"
        case .NinebotX160:      return "bonk"
        }
    }
    
    var scooterProtocol: ScooterProtocol {
        
        switch(self) {
        case let .XiaomiM365(crypto):       return forceNbCrypto ? .ninebot(crypto) : .xiaomi(crypto)
        case let .NinebotESx(crypto):       return                                    .ninebot(crypto)
        case let .XiaomiPro(crypto):        return forceNbCrypto ? .ninebot(crypto) : .xiaomi(crypto)
        case let .NinebotAirT15(crypto):    return                                    .ninebot(crypto)
        case let .NinebotMaxG30(crypto):    return                                    .ninebot(crypto)
        case let .NinebotMaxG65(crypto):    return                                    .ninebot(crypto)
        case let .NinebotMaxG2(crypto):     return                                    .ninebot(crypto)
        case let .NinebotE(crypto):         return                                    .ninebot(crypto)
        case let .NinebotE2(crypto):        return                                    .ninebot(crypto)
        case let .Xiaomi1S(crypto):         return forceNbCrypto ? .ninebot(crypto) : .xiaomi(crypto)
        case let .XiaomiPro2(crypto):       return forceNbCrypto ? .ninebot(crypto) : .xiaomi(crypto)
        case let .XiaomiLite(crypto):       return forceNbCrypto ? .ninebot(crypto) : .xiaomi(crypto)
        case let .Xiaomi3(crypto):          return forceNbCrypto ? .ninebot(crypto) : .xiaomi(crypto)
        case let .NinebotF2(crypto):        return                                    .ninebot(crypto)
        case let .NinebotF(crypto):         return                                    .ninebot(crypto)
        case let .NinebotF65(crypto):       return                                    .ninebot(crypto)
        case let .NinebotGT1(crypto):       return                                    .ninebot(crypto)
        case let .NinebotGT2(crypto):       return                                    .ninebot(crypto)
        case let .NinebotD28(crypto):       return                                    .ninebot(crypto)
        case let .NinebotD38(crypto):       return                                    .ninebot(crypto)
        case let .NinebotD18(crypto):       return                                    .ninebot(crypto)
        case let .NinebotP65(crypto):       return                                    .ninebot(crypto)
        case let .NinebotP100(crypto):      return                                    .ninebot(crypto)
        case let .NinebotX160(crypto):      return                                    .ninebot(crypto)
        }
    }
    
    static func fromAdvertisement(manufactuerData: Data) -> Self? {
        guard manufactuerData.count >= 2 else {
            return nil
        }
        
        let model = manufactuerData[2 + 0]
        let crypto = manufactuerData[2 + 1] == 0x02
        switch(model) {
        case 0x20: return       .XiaomiM365(crypto)
        case 0x21: return       .NinebotESx(crypto)
        case 0x22: return       .XiaomiPro(crypto)
        case 0x23: return       .NinebotAirT15(crypto)
        case 0x24: return       .NinebotMaxG30(crypto)
        case 0x78: return       .NinebotMaxG65(crypto)
        case 0x83: return       .NinebotMaxG2(crypto)
        case 0x27: return       .NinebotE(crypto)
        case 0x7D: return       .NinebotE2(crypto)
        case 0x25, 0x2B: return .Xiaomi1S(crypto)
        case 0x28: return       .XiaomiPro2(crypto)
        case 0x29: return       .XiaomiLite(crypto)
        case 0x2E: return       .Xiaomi3(crypto)
        case 0x7F, 0x80: return .NinebotF2(crypto)
        case 0x7B, 0x2C: return .NinebotF(crypto)
        case 0x2D: return       .NinebotF65(crypto)
        case 0x70: return       .NinebotGT1(crypto)
        case 0x71: return       .NinebotGT2(crypto)
        case 0x72: return       .NinebotD28(crypto)
        case 0x73: return       .NinebotD38(crypto)
        case 0x74: return       .NinebotD18(crypto)
        case 0x76: return       .NinebotP65(crypto)
        case 0x77: return       .NinebotP100(crypto)
        case 0x4A: return       .NinebotX160(crypto)
        default:   return nil
        }
    }
}

enum ScooterProtocol {
    case ninebot(Bool)
    case xiaomi(Bool)
    
    var crypto: Bool {
        switch(self) {
        case let .ninebot(crypto): return crypto
        case let .xiaomi(crytpo): return crytpo
        }
    }
}

class Scooter : ObservableObject {
    var pairing: Bool
    
    @Published var ble: String?
    @Published var esc: String?
    @Published var bms: String?
    @Published var serial: String?
    @Published var uuid: String?
    @Published var model: ScooterModel?
    @Published var battery: Int?
    @Published var shfw: SHFW
    @Published var connectionState: ConnectionState
    
    init() {
        self.pairing = false
        
        self.shfw = SHFW()
        self.connectionState = .disconnected
    }
    
    func reset() {
        self.pairing = false
        
        self.ble = nil
        self.esc = nil
        self.bms = nil
        self.serial = nil
        self.uuid = nil
        self.model = nil
        self.battery = nil
        self.shfw = SHFW()
        self.connectionState = .disconnected
    }
}
