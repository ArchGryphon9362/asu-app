//
//  NinebotMessage.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/02/2024.
//

import Foundation

struct NinebotRegisterInfo {
    var address: UInt8
    var amount: UInt8 = 2
}

struct NinebotVersion {
    let raw: Data
    var parsed: String {
        guard self.raw.count >= 2 else { return "" }
        
        let first  = (self.raw[0] & 0xF0) >> 4
        let second = (self.raw[0] & 0x0F) >> 0
        let third  = (self.raw[1] & 0xF0) >> 4
        let forth  = (self.raw[1] & 0x0F) >> 0
        
        let firstPart = first != 0 ? "\(first)." : ""
        let result = "\(second).\(third).\(forth)"
        return firstPart + result
    }
}

enum NinebotMessage: CaseIterable {
    static var allCases: [NinebotMessage] = [
        .serialNumber(),
        .escVersion(),
        .actualDistance(),
        .ridingTime(),
        .bat1Temp(),
        .bat2Temp(),
        .systemVoltage(),
        .phaseCurrent(),
        .extBmsVersion(),
        .bmsVersion(),
        .bleVersion(),
        .lock(),
        .speedLimit(),
        .driveMode(),
        .powerOff(),
        .cruiseControl(),
        .functionSetup(),
        .infoDump(),
    ]
    
    struct ErrorCode: Equatable {
        let code: UInt16
        var shortDescription: String? {
            switch self.code {
            case  0: "No error"
            case 10: "BLE or ESC failure"
            case 11: "Phase A sensor failure"
            case 12: "Phase B sensor failure"
            case 13: "Phase C sensor failure"
            case 14: "Throttle handle failure"
            case 15: "Brake handle failure"
            case 18: "Hall sensors failure"
            case 19: "Wrong main battery voltage"
            case 20: "Wrong ext battery voltage"
            case 21: "No BMS data"
            case 22: "Invalid BMS config"
            case 23: "BMS has default S/N"
            case 24: "Supply voltage out of range"
            case 27: "ESC config invalid (change SN)"
            case 32: "Missing IoT device"
            case 35: "ESC has default S/N"
            case 36: "eBMS connector or charging failure"
            case 37: "BMS connector or charging failure"
            case 38: "Charging over-current"
            case 39: "Battery overheat"
            case 41: "Ext battery overheat"
            case 42: "No eBMS data"
            case 43: "Invalid eBMS config"
            case 44: "eBMS has default S/N"
            case 45: "Battery cell deep discharge"
            case 46: "Ext battery cell deep discharge"
            case 49: "Wrong BMS firmware version"
            case 50: "Wrong eBMS firmware version"
            case 51: "Wrong BLE firmware version"
            case 52: "BMS firmware incompatible with DRV"
            case 53: "Incompatible external battery"
            case 54: "Motor C phase disconnected"
            default: nil
            }
        }
    }
    
    enum AlarmCode {
        case none
        case locked
        case excessRegen
        
        static func parse(_ code: UInt16) -> Self {
            switch code {
            case 9: .locked
            case 12: .excessRegen
            default: .none
            }
        }
    }
    
    struct ScooterStatus: Equatable {
        var speedLimit: Bool = false
        var lock: Bool = false
        var beep: Bool = false
        var bat2In: Bool = false
        var activated: Bool = false
        
        static func parse(_ value: UInt16) -> Self {
            .init(
                speedLimit: value & (1 <<  0) > 0,
                lock:       value & (1 <<  1) > 0,
                beep:       value & (1 <<  2) > 0,
                bat2In:     value & (1 <<  9) > 0,
                activated:  value & (1 << 11) > 0
            )
        }
    }
    
    struct FunctionSetup {
        var taillightAlwaysOn: Bool = false
        var wrongUnits: Bool = false
        
        var int: UInt8 {
            let taillight = self.taillightAlwaysOn ? 0x02 : 0x00
            let wrongUnit = self.wrongUnits        ? 0x10 : 0x00
            
            return UInt8(taillight + wrongUnit)
        }
        
        static func fromInt(_ int: UInt8) -> Self {
            let taillight = int & 0x02 > 0
            let wrongUnit = int & 0x10 > 0
            return .init(
                taillightAlwaysOn: taillight,
                wrongUnits: wrongUnit
            )
        }
    }
    
    struct InfoDump: Equatable {
        var errorCode: ErrorCode = .init(code: 0)
        var alarmCode: AlarmCode = .none
        var scooterStatus: ScooterStatus = .init()
        var bat1Pct: Float = 0
        var bat2Pct: Float = 0
        var chargePct: Float = 0
        var speed: Float = 0
        var averageSpeed: Float = 0
        var mileage: Float = 0
        var uptime: Int = 0
        var bodyTemp: Float = 0
        var speedLimit: Float = 0
        var wattage: Int = 0
        var predictedDistance: Float = 0
    }
    
    enum DriveMode: CaseIterable {
        case eco
        case drive
        case sport
        
        var int: UInt8 {
            switch self {
            case .eco:   1
            case .drive: 0
            case .sport: 2
            }
        }
        
        static func fromInt(_ int: UInt8) -> Self {
            switch int {
            case 0x01: .eco
            case 0x02: .sport
            default:   .drive
            }
        }
    }
    
    case serialNumber(String = "")
    case escVersion(NinebotVersion = .init(raw: Data()))
//    case errorCode(ErrorCode)
//    case alarmCode(AlarmCode)
//    case scooterStatus(ScooterStatus)
//    case bat1Pct(Float)
//    case bat2Pct(Float)
//    case chargePct(Float)
    case actualDistance(Float = 0)
//    case predictedDistance(Float)
//    case speed(Float)
//    case mileage(Int)
//    case uptime(Int)
    case ridingTime(Int = 0)
//    case bodyTemp(Float)
    case bat1Temp(Float = 0)
    case bat2Temp(Float = 0)
    case systemVoltage(Float = 0)
    case phaseCurrent(Float = 0)
//    case averageSpeed(Float)
    case extBmsVersion(NinebotVersion = .init(raw: Data()))
    case bmsVersion(NinebotVersion = .init(raw: Data()))
    case bleVersion(NinebotVersion = .init(raw: Data()))
    case lock(Bool = false)
    case speedLimit(Float = 0)
    case driveMode(DriveMode = .drive)
    case powerOff(Bool = false) // plus reboot
    case cruiseControl(Bool = false)
    case functionSetup(FunctionSetup = .init())
    case infoDump(InfoDump = .init())
    // TODO: add LED strip settings
    // TODO: add BMS readouts
    
    private var registerInfo: NinebotRegisterInfo {
        switch self {
        case .serialNumber(_):   NinebotRegisterInfo(address: 0x10, amount: 14)
        case .escVersion(_):     NinebotRegisterInfo(address: 0x1a)
        case .actualDistance(_): NinebotRegisterInfo(address: 0x24)
        case .ridingTime(_):     NinebotRegisterInfo(address: 0x34, amount: 4)
        case .bat1Temp(_):       NinebotRegisterInfo(address: 0x3f)
        case .bat2Temp(_):       NinebotRegisterInfo(address: 0x40)
        case .systemVoltage(_):  NinebotRegisterInfo(address: 0x47)
        case .phaseCurrent(_):   NinebotRegisterInfo(address: 0x53)
        case .extBmsVersion(_):  NinebotRegisterInfo(address: 0x66)
        case .bmsVersion(_):     NinebotRegisterInfo(address: 0x67)
        case .bleVersion(_):     NinebotRegisterInfo(address: 0x68)
        case .lock(_):           NinebotRegisterInfo(address: 0x70)
        case .speedLimit(_):     NinebotRegisterInfo(address: 0x72)
        case .driveMode(_):      NinebotRegisterInfo(address: 0x75)
        case .powerOff(_):       NinebotRegisterInfo(address: 0x79)
        case .cruiseControl(_):  NinebotRegisterInfo(address: 0x7c)
        case .functionSetup(_):  NinebotRegisterInfo(address: 0x7d)
        case .infoDump(_):       NinebotRegisterInfo(address: 0xb0, amount: 32)
        }
    }
    
    static func getMessageType(address: UInt8) -> Self? {
        return Self.allCases.first(where: { message in message.registerInfo.address == address })
    }
    
    static func parse(_ data: Data, address: UInt8) -> Self? {
        guard let message = self.getMessageType(address: address),
              data.count == message.registerInfo.amount else {
            return nil
        }
        
        switch message {
        case .serialNumber(_):
            guard let serialNumber = String(data: Data(data[..<14]), encoding: .ascii) else {
                return nil
            }
            return .serialNumber(serialNumber)
        case .escVersion(_): return .escVersion(.init(raw: Data([data[1], data[0]])))
        case .actualDistance(_): return .actualDistance(Float(dataToUInt16(data)) / 10)
        case .ridingTime(_): return .ridingTime(Int(dataToUInt16(data)))
        case .bat1Temp(_): return .bat1Temp(Float(dataToInt16(data)) / 10)
        case .bat2Temp(_): return .bat2Temp(Float(dataToInt16(data)) / 10)
        case .systemVoltage(_): return .systemVoltage(Float(dataToUInt16(data)) / 100)
        case .phaseCurrent(_): return .phaseCurrent(Float(dataToInt16(data)) / 100)
        case .extBmsVersion(_): return .bmsVersion(.init(raw: Data([data[1], data[0]])))
        case .bmsVersion(_): return .bmsVersion(.init(raw: Data([data[1], data[0]])))
        case .bleVersion(_): return .bleVersion(.init(raw: Data([data[1], data[0]])))
        case .lock(_): return .lock(data[0] == 1)
        case .speedLimit(_): return .speedLimit(Float(dataToUInt16(data)) / 10)
        case .driveMode(_): return .driveMode(.fromInt(data[0]))
        case .cruiseControl(_): return .cruiseControl(data[0] == 1)
        case .functionSetup(_): return .functionSetup(.fromInt(data[0]))
        case .infoDump(_):
            let errorCode = ErrorCode(code: dataToUInt16(data[(0x00 * 2)...].prefix(2)))
            let alarmCode = AlarmCode.parse(dataToUInt16(data[(0x01 * 2)...].prefix(2)))
            let scooterStatus = ScooterStatus.parse(dataToUInt16(data[(0x02 * 2)...].prefix(2)))
            let bat1Pct = Float(data[(0x03 * 2 + 0x00)]) / 100
            let bat2Pct = Float(data[(0x03 * 2 + 0x01)]) / 100
            let chargePct = Float(dataToUInt16(data[(0x04 * 2)...].prefix(2))) / 100
            let speed = Float(dataToUInt16(data[(0x05 * 2)...].prefix(2))) / 10
            let averageSpeed = Float(dataToUInt16(data[(0x06 * 2)...].prefix(2))) / 10
            let mileage = Float(dataToUInt32(data[(0x07 * 2)...].prefix(4))) / 1000
            let uptime = Int(dataToUInt16(data[(0x0a * 2)...].prefix(2)))
            let bodyTemp = Float(dataToInt16(data[(0x0b * 2)...].prefix(2))) / 10
            let speedLimit = Float(data[(0x0c * 2)]) / 10
            let wattage = Int(dataToInt16(data[(0x0d * 2)...].prefix(2)))
            let predictedDistance = Float(dataToUInt16(data[(0x0f * 2)...].prefix(2))) / 10
            return .infoDump(.init(
                errorCode: errorCode,
                alarmCode: alarmCode,
                scooterStatus: scooterStatus,
                bat1Pct: bat1Pct,
                bat2Pct: bat2Pct,
                chargePct: chargePct,
                speed: speed,
                averageSpeed: averageSpeed,
                mileage: mileage,
                uptime: uptime,
                bodyTemp: bodyTemp,
                speedLimit: speedLimit,
                wattage: wattage,
                predictedDistance: predictedDistance
            ))
        default: return nil
        }
    }
    
    func read() -> Data? {
        let address = self.registerInfo.address
        let amount = self.registerInfo.amount
        
        switch self {
        case .powerOff: return nil
        default: return Data([0x01, address, amount])
        }
    }
    
    func write(ack: Bool) -> Data? {
        let address = self.registerInfo.address
        let cmd: UInt8 = ack ? 0x02 : 0x03
        
        switch self {
        case let .lock(lock): return Data([cmd, address + (lock ? 0 : 1), 0x01, 0x00])
        case let .speedLimit(speed):
            let speed = Int(speed * 10)
            let speedLower = UInt8((speed & 0x00ff) >> 0)
            let speedUpper = UInt8((speed & 0xff00) >> 8)
            return Data([cmd, address, speedLower, speedUpper])
        case let .driveMode(driveMode): return Data([cmd, address, driveMode.int, 0x00])
        case let .powerOff(reboot): return Data([cmd, address - (reboot ? 1 : 0), 0x01, 0x00])
        case let .cruiseControl(cruise): return Data([cmd, address, cruise ? 1 : 0, 0x00])
        case let .functionSetup(functions): return Data([cmd, address, functions.int, 0x00])
        default: return nil
        }
    }
}
