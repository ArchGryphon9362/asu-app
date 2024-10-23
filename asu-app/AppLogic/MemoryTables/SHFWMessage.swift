//
//  SHFWMessage.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 14/07/2024.
//

import Foundation

struct SHFWVersion: Equatable {
    struct ExtraDetails: Equatable {
        enum BuildType: Equatable {
            case production
            case prerelease
            case beta
            case development
            case unknown(Int)
            
            var string: String {
                switch self {
                case .production: "production"
                case .prerelease: "pre-release"
                case .beta: "beta"
                case .development: "development"
                case let .unknown(value): "unknown (\(value))"
                }
            }
        }
        
        let buildType: BuildType
        let buildDetails: String?
    }
    
    let extraDetails: ExtraDetails?
    let newVersioning: Bool
    
    private let extra: Int
    private let major: Int
    private let minor: Int
    private let patch: Int
    
    init() {
        self.extraDetails = nil
        self.newVersioning = false
        self.extra = 0
        self.major = 0
        self.minor = 0
        self.patch = 0
    }
    
    var parsed: String {
        return ""
    }
}

enum SHFWMessage: CaseIterable, NinebotMessage {
    static var allCases: [SHFWMessage] = [
        .shfwMagic(),
        .profileCore(0),
        .profileExtra(0),
        .profileItem(0, .fwkVarCurrent()),
        .systemSettings(),
        .extraSystemSettings(),
        .systemSetting(.wheelSize()),
        .version(),
        .newVersion()
    ]
    
    struct SpeedBasedConfig: Equatable {
        var speedLimit: Int = 0
        var smoothness: Int = 0
    }
    
    enum BrakeLightMode: Equatable {
        case normal
        case single
        case reversed
        case strobe
        case german
        case car
        
        case unknown(Int)
    }
    
    struct BrakeLightConfig: Equatable {
        var mode: BrakeLightMode = .normal
        var flashSpeed: Int = 241
    }
    
    struct ProfileBoolean: Equatable {
        var swapButton: Bool = false
        var noPowerBeep: Bool = false
        var alwaysHeadlight: Bool = false
        var alwaysBacklight: Bool = false
        var sportsOnly: Bool = false
        var ecoSpeedBased: Bool = false
        var driveSpeedBased: Bool = false
        var sportsSpeedBased: Bool = false
        var ccSpeedBased: Bool = false
        var ccUseThrottlePos: Bool = false
        var fwkEco: Bool = false
        var fwkDrive: Bool = false
        var fwkSports: Bool = false
    }
    
    struct NewProfileBoolean: Equatable {
        var negativeMsp: Bool = false
        var ecoOvermod: Bool = false
        var driveOvermod: Bool = false
        var sportsOvermod: Bool = false
    }
    
    enum DashData: Equatable {
        case off
        case speedKm
        case speedMi
        case speedMe
        case avgSpeedKm
        case avgSpeedMi
        case avgSpeedMe
        case tripMileage
        case batteryTemp
        case batteryLevel
        case systemVoltage
        case uptime
        case throttle
        case brake
        case ccSpeedMi
        case ccSpeedKm
        case current
        case power
        case remainingKm
        case escTemp
        case motorTemp
        case escTempG2
        
        case unknown(Int = 0)
    }
    
    enum BatteryBarData: Equatable {
        case off
        case throttle
        case brake
        case percentageAmps
        case percentageSpeed
        case activeProfile
        
        case unknown(Int)
    }
    
    enum CCMode: Equatable {
        case off
        case time
        case single
        case double
        
        case unknown(Int)
    }
    
    enum Beep: Equatable {
        case none
        case single
        case long
        case double
        case extraLong
        
        case unknown(Int)
    }
    
    enum DriveMode: Equatable {
        case last
        case eco
        case drive
        case sports
        
        case unknown(Int)
    }
    
    struct ProfileSequence: Equatable {
        enum Action: Equatable {
            case none
            case throttle
            case brake
            case single
            case double
            case unknown(Int)
        }
        
        var sequence: [Action] = []
    }
    
    enum BMSEmuSeries: Equatable {
        case none
        case s10
        case s11
        case s12
        case s13
        case s14
        case s15
        case s16
        case s17
        case s18
        case s19
        case s20
        
        case unknown(Int)
    }
    
    struct ProfileData {
        enum ProfileItem: CaseIterable {
            static var allCases: [Self] = [
                .ecoAmps(),
                .ecoAmps1(),
                .ecoAmps2(),
                .ecoAmps3(),
                .ecoAmps4(),
                .driveAmps(),
                .driveAmps1(),
                .driveAmps2(),
                .driveAmps3(),
                .driveAmps4(),
                .sportsAmps(),
                .sportsAmps1(),
                .sportsAmps2(),
                .sportsAmps3(),
                .sportsAmps4(),
                .brakeAmps(),
                .brakeAmps1(),
                .brakeAmps2(),
                .brakeAmps3(),
                .brakeAmps4(),
                .ecoSmoothness(),
                .driveSmoothness(),
                .sportsSmoothness(),
                .mspBrakeBoost(),
                .brakeLight(),
                .booleans(),
                .idleSpeedData(),
                .alternatingBatteryBarData(),
                .ccModeBeep(),
                .ccDelayExitBeep(),
                .initModeBeep(),
                .brakeMspOvershoot(),
                .ccChangeTimeAutobrakingAmps(),
                .fwkSpeedCurrent(),
                .fwkVarCurrent(),
                .maxFieldTorqueCurrent(),
                .accelerationBoost(),
                .newBooleans()
            ]
            
            case ecoAmps(Float = 0, Float = 0, Float = 0, Float = 0)
            case ecoAmps1(Float = 0)
            case ecoAmps2(Float = 0)
            case ecoAmps3(Float = 0)
            case ecoAmps4(Float = 0)
            case driveAmps(Float = 0, Float = 0, Float = 0, Float = 0)
            case driveAmps1(Float = 0)
            case driveAmps2(Float = 0)
            case driveAmps3(Float = 0)
            case driveAmps4(Float = 0)
            case sportsAmps(Float = 0, Float = 0, Float = 0, Float = 0)
            case sportsAmps1(Float = 0)
            case sportsAmps2(Float = 0)
            case sportsAmps3(Float = 0)
            case sportsAmps4(Float = 0)
            case brakeAmps(Float = 0, Float = 0, Float = 0, Float = 0)
            case brakeAmps1(Float = 0)
            case brakeAmps2(Float = 0)
            case brakeAmps3(Float = 0)
            case brakeAmps4(Float = 0)
            case ecoSmoothness(SpeedBasedConfig = .init())
            case driveSmoothness(SpeedBasedConfig = .init())
            case sportsSmoothness(SpeedBasedConfig = .init())
            case mspBrakeBoost(Int = 0, Int = 0)
            case brakeLight(BrakeLightConfig = .init())
            case booleans(ProfileBoolean = .init())
            case idleSpeedData(DashData = .off, DashData = .speedKm)
            case alternatingBatteryBarData(DashData = .off, BatteryBarData = .off)
            case ccModeBeep(CCMode = .off, Beep = .none)
            case ccDelayExitBeep(Int = 0, Beep = .none)
            case initModeBeep(DriveMode = .last, Beep = .none)
            case brakeMspOvershoot(Int = 0, Int = 0)
            case ccChangeTimeAutobrakingAmps(Float = 0, Int = 0)
            
            case fwkSpeedCurrent(Int = 0, Int = 0)
            case fwkVarCurrent(Int = 0)
            case maxFieldTorqueCurrent(Int = 0, Int = 0)
            case accelerationBoost(Int = 0)
            case newBooleans(NewProfileBoolean = .init())
        }
        
        var ecoAmps: [Float] = []
        var driveAmps: [Float] = []
        var sportsAmps: [Float] = []
        var brakeAmps: [Float] = []
        var ecoSmoothness: SpeedBasedConfig = .init()
        var driveSmoothness: SpeedBasedConfig = .init()
        var sportsSmoothness: SpeedBasedConfig = .init()
        var msp: Int = 0
        var brakeBoost: Int = 0
        var brakeLight: BrakeLightConfig = .init(mode: .normal, flashSpeed: 241)
        var booleans: ProfileBoolean = .init()
        var idleData: DashData = .off
        var speedData: DashData = .speedKm
        var alternatingData: DashData = .off
        var batteryBarData: BatteryBarData = .off
        var ccMode: CCMode = .off
        var ccEnterBeep: Beep = .none
        var ccDelay: Int = 5
        var ccExitBeep: Beep = .none
        var initMode: DriveMode = .last
        var initBeep: Beep = .none
        var brakeMsp: Int = 0
        var brakeOvershoot: Int = 0
        var ccChangeTime: Float = 0.7
        var autobrakeAmps: Int = 0
    }
    
    struct ProfileExtraData {
        var fwkSpeed: Int = 0
        var fwkCurrent: Int = 0
        var fwkVarCurrent: Int = 0
        var maxFieldCurrent: Int = 0
        var maxTorqueCurrent: Int = 0
        var accelerationBoost: Int = 0
        var booleans: NewProfileBoolean = .init()
    }
    
    struct GlobalBoolean: Equatable {
        var errorSuppresion: Bool = false
        var noChargingMode: Bool = false
        var spoofBms: Bool = false
        var spoofBle: Bool = false
        var motorOff: Bool = false
        var noAutobrakeLight: Bool = false
        var keySwitch: Bool = false
        var newMotors: Bool = false
    }
        
    struct SystemSettings {
        enum Setting: CaseIterable {
            static var allCases: [SHFWMessage.SystemSettings.Setting] = [
                .activeProfile(),
                .defaultProfile(),
                .brakeProfile(),
                .throttleProfile(),
                .brakeThrottleBootProfile(),
                .brakeButtonProfile(),
                .brakeDoubleButtonProfile(),
                .brakeThrottleProfile(),
                .sequenceProfile(),
                
                .pidKdLowerLimit(),
                .pidKpKi(),
                .minMaxBrake(),
                .minMaxThrottle(),
                .taillightBrightness(),
                .idleTimeout(),
                .lockedTimeout(),
                .wheelSize(),
                .bmsEmuSeries(),
                .bmsEmuAdc(),
                .bmsEmuCapacity(),
                .bmsEmuMinMaxCell(),
                .booleans()
            ]
            
            case activeProfile(Int = 0)
            case defaultProfile(Int = 0)
            case brakeProfile(Int = 0)
            case throttleProfile(Int = 0)
            case brakeThrottleBootProfile(Int = 0)
            case brakeButtonProfile(Int = 0)
            case brakeDoubleButtonProfile(Int = 0)
            case brakeThrottleProfile(Int = 0)
            case sequenceProfile(Int = 0, ProfileSequence = .init())
            
            case pwm(Int = 0)
            case pidKdLowerLimit(Int = 0, Int = 0)
            case pidKpKi(Int = 0, Int = 0)
            case minMaxBrake(Int = 0, Int = 0)
            case minMaxThrottle(Int = 0, Int = 0)
            case taillightBrightness(Int = 0)
            case idleTimeout(Int = 0)
            case lockedTimeout(Int = 0)
            case wheelSize(Float = 0)
            case bmsEmuSeries(BMSEmuSeries = .none)
            case bmsEmuAdc(Float = 0)
            case bmsEmuCapacity(Int = 0)
            case bmsEmuMinMaxCell(Float = 0, Float = 0)
            case booleans(GlobalBoolean = .init())
        }
        
        var activeProfile: Int = 0
        var defaultProfile: Int = 0
        var brakeProfile: Int = 0
        var throttleProfile: Int = 0
        var brakeThrottleBootProfile: Int = 0
        var brakeButtonProfile: Int = 0
        var brakeDoubleButtonProfile: Int = 0
        var brakeThrottleProfile: Int = 0
        var sequenceProfile: Int = 0
        var sequenceProfileData: ProfileSequence = .init()
    }
    
    struct ExtraSystemSettings {
        var pwm: Int = 0
        var pidKd: Int = 0
        var pidLowerLimit: Int = 0
        var pidKp: Int = 0
        var pidKi: Int = 0
        var minThrottle: Int = 0
        var maxThrottle: Int = 0
        var minBrake: Int = 0
        var maxBrake: Int = 0
        var taillightBrightness: Int = 0
        var idleTimeout: Int = 0
        var lockedTimeout: Int = 0
        var wheelSize: Float = 0
        var bmsEmuSeries: BMSEmuSeries = .none
        var bmsEmuAdc: Float = 0
        var bmsEmuCapacity: Int = 0
        var bmsEmuMinCell: Float = 0
        var bmsEmuMaxCell: Float = 0
        var booleans: GlobalBoolean = .init()
    }
    
    case shfwMagic(Data = Data())
    case profileCore(Int, ProfileData = .init(), Data = Data())
    case profileExtra(Int, ProfileExtraData = .init(), Data = Data())
    case profileItem(Int, ProfileData.ProfileItem)
    case systemSettings(SystemSettings = .init(), Data = Data())
    case extraSystemSettings(ExtraSystemSettings = .init(), Data = Data())
    case systemSetting(SystemSettings.Setting)
    case version(SHFWVersion = .init())
    case newVersion(SHFWVersion = .init())
    case resetSHFW
    
    static func getMessageType(address: UInt8, size: UInt8) -> Self? {
        return nil
    }
    
    static func parse(_ data: Data, address: UInt8) -> Self? {
        return nil
    }
    
    static func parseNewVersion(_ data: Data) -> Self? {
        return nil
    }
    
    func read() -> Data? {
        print("[SHFWMessage]", "an shfw read command has just been generated, but the memory table is a stub. shfw functionality will behave as if not installed. file stubbed as per request of ScooterHacking")
        return nil
    }
    
    func write(ack: Bool) -> Data? {
        print("[SHFWMessage]", "an shfw write command has just been generated, but the memory table is a stub. shfw functionality will behave as if not installed. file stubbed as per request of ScooterHacking")
        return nil
    }
}
