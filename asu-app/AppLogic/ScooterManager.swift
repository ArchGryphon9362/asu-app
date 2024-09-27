//
//  ScooterManager.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation
import OrderedCollections
import CoreBluetooth

fileprivate func configBinding<T>(scooterManager: ScooterManager, getValue: @escaping () -> (T), request: @escaping (T) -> (SHFWMessage?)) -> Binding<T> {
    return Binding(get: {
        getValue()
    }, set: { newValue in
        guard let requestMsg = request(newValue) else {
            return
        }
        
        scooterManager.writeRaw(
            scooterManager.messageManager.ninebotWrite(requestMsg, ack: false),
            characteristic: .serial,
            writeType: .foreverLimitTimes(times: 2)
        )
        scooterManager.writeRaw(
            scooterManager.messageManager.ninebotRead(requestMsg),
            characteristic: .serial,
            writeType: .foreverLimitTimes(times: 2)
        )
    })
}

class ScooterManager : ObservableObject, ScooterBluetoothDelegate {
    class CoreInfo : Observable {
        @Published fileprivate(set) var serial: String? = nil
        @Published fileprivate(set) var esc: NinebotVersion? = nil
        @Published fileprivate(set) var ble: NinebotVersion? = nil
        @Published fileprivate(set) var bms: NinebotVersion? = nil
        
        // init code
        private var scooterManager: ScooterManager! = nil
        
        fileprivate func setScooterManager(_ scooterManager: ScooterManager) {
            self.scooterManager = scooterManager
        }
    }
    
    class SHFWProfile : ObservableObject {
        fileprivate var _ecoAmps: [Float] = []
        var ecoAmps: Binding<[Float]>!
        
        fileprivate var _driveAmps: [Float] = []
        var driveAmps: Binding<[Float]>!

        fileprivate var _sportsAmps: [Float] = []
        var sportsAmps: Binding<[Float]>!

        fileprivate var _brakeAmps: [Float] = []
        var brakeAmps: Binding<[Float]>!

        fileprivate var _ecoSmoothness: SHFWMessage.SpeedBasedConfig = .init()
        var ecoSmoothness: Binding<SHFWMessage.SpeedBasedConfig>!

        fileprivate var _driveSmoothness: SHFWMessage.SpeedBasedConfig = .init()
        var driveSmoothness: Binding<SHFWMessage.SpeedBasedConfig>!

        fileprivate var _sportsSmoothness: SHFWMessage.SpeedBasedConfig = .init()
        var sportsSmoothness: Binding<SHFWMessage.SpeedBasedConfig>!

        fileprivate var _msp: Int = 0
        var msp: Binding<Int>!

        fileprivate var _brakeBoost: Int = 0
        var brakeBoost: Binding<Int>!

        fileprivate var _brakeLight: SHFWMessage.BrakeLightConfig = .init()
        var brakeLight: Binding<SHFWMessage.BrakeLightConfig>!

        fileprivate var _booleans: SHFWMessage.ProfileBoolean = .init()
        var booleans: Binding<SHFWMessage.ProfileBoolean>!

        fileprivate var _idleData: SHFWMessage.DashData = .unknown(0)
        var idleData: Binding<SHFWMessage.DashData>!

        fileprivate var _speedData: SHFWMessage.DashData = .unknown(0)
        var speedData: Binding<SHFWMessage.DashData>!

        fileprivate var _alternatingData: SHFWMessage.DashData = .unknown(0)
        var alternatingData: Binding<SHFWMessage.DashData>!

        fileprivate var _batteryBarData: SHFWMessage.BatteryBarData = .unknown(0)
        var batteryBarData: Binding<SHFWMessage.BatteryBarData>!

        fileprivate var _ccMode: SHFWMessage.CCMode = .unknown(0)
        var ccMode: Binding<SHFWMessage.CCMode>!

        fileprivate var _ccEnterBeep: SHFWMessage.Beep = .unknown(0)
        var ccEnterBeep: Binding<SHFWMessage.Beep>!

        fileprivate var _ccDelay: Int = 0
        var ccDelay: Binding<Int>!

        fileprivate var _ccExitBeep: SHFWMessage.Beep = .unknown(0)
        var ccExitBeep: Binding<SHFWMessage.Beep>!

        fileprivate var _initMode: SHFWMessage.DriveMode = .unknown(0)
        var initMode: Binding<SHFWMessage.DriveMode>!

        fileprivate var _initBeep: SHFWMessage.Beep = .unknown(0)
        var initBeep: Binding<SHFWMessage.Beep>!

        fileprivate var _brakeMsp: Int = 0
        var brakeMsp: Binding<Int>!

        fileprivate var _brakeOvershoot: Int = 0
        var brakeOvershoot: Binding<Int>!

        fileprivate var _ccChangeTime: Float = 0
        var ccChangeTime: Binding<Float>!

        fileprivate var _autobrakeAmps: Int = 0
        var autobrakeAmps: Binding<Int>!

        fileprivate var _fwkSpeed: Int = 0
        var fwkSpeed: Binding<Int>!

        fileprivate var _fwkCurrent: Int = 0
        var fwkCurrent: Binding<Int>!

        fileprivate var _fwkVarCurrent: Int = 0
        var fwkVarCurrent: Binding<Int>!

        fileprivate var _maxFieldCurrent: Int = 0
        var maxFieldCurrent: Binding<Int>!

        fileprivate var _maxTorqueCurrent: Int = 0
        var maxTorqueCurrent: Binding<Int>!

        fileprivate var _accelerationBoost: Int = 0
        var accelerationBoost: Binding<Int>!

        fileprivate var _newBooleans: SHFWMessage.NewProfileBoolean = .init()
        var newBooleans: Binding<SHFWMessage.NewProfileBoolean>!
        
        init(
            profile: Int,
            scooterManager: ScooterManager,
            ecoAmps: [Float],
            driveAmps: [Float],
            sportsAmps: [Float],
            brakeAmps: [Float],
            ecoSmoothness: SHFWMessage.SpeedBasedConfig,
            driveSmoothness: SHFWMessage.SpeedBasedConfig,
            sportsSmoothness: SHFWMessage.SpeedBasedConfig,
            msp: Int,
            brakeBoost: Int,
            brakeLight: SHFWMessage.BrakeLightConfig,
            booleans: SHFWMessage.ProfileBoolean,
            idleData: SHFWMessage.DashData,
            speedData: SHFWMessage.DashData,
            alternatingData: SHFWMessage.DashData,
            batteryBarData: SHFWMessage.BatteryBarData,
            ccMode: SHFWMessage.CCMode,
            ccEnterBeep: SHFWMessage.Beep,
            ccDelay: Int,
            ccExitBeep: SHFWMessage.Beep,
            initMode: SHFWMessage.DriveMode,
            initBeep: SHFWMessage.Beep,
            brakeMsp: Int,
            brakeOvershoot: Int,
            ccChangeTime: Float,
            autobrakeAmps: Int,
            fwkSpeed: Int,
            fwkCurrent: Int,
            fwkVarCurrent: Int,
            maxFieldCurrent: Int,
            maxTorqueCurrent: Int,
            accelerationBoost: Int,
            newBooleans: SHFWMessage.NewProfileBoolean
        ) {
            func i<T>(
                _ valuePath: ReferenceWritableKeyPath<ScooterManager.SHFWProfile, T>,
                _ initial: T,
                c condition: @escaping (T) -> (Bool) = { _ in true },
                _ request: @escaping (T) -> (SHFWMessage.ProfileData.ProfileItem)
            ) -> Binding<T> {
                self[keyPath: valuePath] = initial
                
                return configBinding(scooterManager: scooterManager, getValue: { self[keyPath: valuePath] }) { newValue in
                    guard condition(newValue) else { return nil }
                    return SHFWMessage.profileItem(profile, request(newValue))
                }
            }
            
            self.ecoAmps = i(\._ecoAmps, ecoAmps, c: { v in v.count >= 4 }, { v in .ecoAmps(v[0], v[1], v[2], v[3]) })
            self.driveAmps = i(\._driveAmps, driveAmps, c: { v in v.count >= 4 }, { v in .driveAmps(v[0], v[1], v[2], v[3]) })
            self.sportsAmps = i(\._sportsAmps, sportsAmps, c: { v in v.count >= 4 }, { v in .sportsAmps(v[0], v[1], v[2], v[3]) })
            self.brakeAmps = i(\._brakeAmps, brakeAmps, c: { v in v.count >= 4 }, { v in .brakeAmps(v[0], v[1], v[2], v[3]) })
            self.ecoSmoothness = i(\._ecoSmoothness, ecoSmoothness, { v in .ecoSmoothness(v) })
            self.driveSmoothness = i(\._driveSmoothness, driveSmoothness, { v in .driveSmoothness(v) })
            self.sportsSmoothness = i(\._sportsSmoothness, sportsSmoothness, { v in .sportsSmoothness(v) })
            self.msp = i(\._msp, msp, { v in .mspBrakeBoost(v, self._brakeBoost) })
            self.brakeBoost = i(\._brakeBoost, brakeBoost, { v in .mspBrakeBoost(self._msp, v) })
            self.brakeLight = i(\._brakeLight, brakeLight, { v in .brakeLight(v) })
            self.booleans = i(\._booleans, booleans, { v in .booleans(v) })
            self.idleData = i(\._idleData, idleData, { v in .idleSpeedData(v, self._speedData) })
            self.speedData = i(\._speedData, speedData, { v in .idleSpeedData(self._idleData, v) })
            self.alternatingData = i(\._alternatingData, alternatingData, { v in .alternatingBatteryBarData(v, self._batteryBarData) })
            self.batteryBarData = i(\._batteryBarData, batteryBarData, { v in .alternatingBatteryBarData(self._alternatingData, v) })
            self.ccMode = i(\._ccMode, ccMode, { v in .ccModeBeep(v, self._ccEnterBeep) })
            self.ccEnterBeep = i(\._ccEnterBeep, ccEnterBeep, { v in .ccModeBeep(self._ccMode, v) })
            self.ccDelay = i(\._ccDelay, ccDelay, { v in .ccDelayExitBeep(v, self._ccExitBeep) })
            self.ccExitBeep = i(\._ccExitBeep, ccExitBeep, { v in .ccDelayExitBeep(self._ccDelay, v) })
            self.initMode = i(\._initMode, initMode, { v in .initModeBeep(v, self._initBeep) })
            self.initBeep = i(\._initBeep, initBeep, { v in .initModeBeep(self._initMode, v) })
            self.brakeMsp = i(\._brakeMsp, brakeMsp, { v in .brakeMspOvershoot(v, self._brakeOvershoot) })
            self.brakeOvershoot = i(\._brakeOvershoot, brakeOvershoot, { v in .brakeMspOvershoot(self._brakeMsp, v) })
            self.ccChangeTime = i(\._ccChangeTime, ccChangeTime, { v in .ccChangeTimeAutobrakingAmps(v, self._autobrakeAmps) })
            self.autobrakeAmps = i(\._autobrakeAmps, autobrakeAmps, { v in .ccChangeTimeAutobrakingAmps(self._ccChangeTime, v) })
            self.fwkSpeed = i(\._fwkSpeed, fwkSpeed, { v in .fwkSpeedCurrent(v, self._fwkCurrent) })
            self.fwkCurrent = i(\._fwkCurrent, fwkCurrent, { v in .fwkSpeedCurrent(self._fwkSpeed, v) })
            self.fwkVarCurrent = i(\._fwkVarCurrent, fwkVarCurrent, { v in .fwkVarCurrent(v) })
            self.maxFieldCurrent = i(\._maxFieldCurrent, maxFieldCurrent, { v in .maxFieldTorqueCurrent(v, self._maxTorqueCurrent) })
            self.maxTorqueCurrent = i(\._maxTorqueCurrent, maxTorqueCurrent, { v in .maxFieldTorqueCurrent(self._maxFieldCurrent, v) })
            self.accelerationBoost = i(\._accelerationBoost, accelerationBoost, { v in .accelerationBoost(v) })
            self.newBooleans = i(\._newBooleans, newBooleans, { v in .newBooleans(v) })
        }
    }
    
    class SHFWConfig : Observable {
        @Published fileprivate(set) var profile1: SHFWProfile
        @Published fileprivate(set) var profile2: SHFWProfile
        @Published fileprivate(set) var profile3: SHFWProfile
        
        func getProfile(_ profile: Int) -> SHFWProfile {
            return [self.profile1, self.profile2, self.profile3][profile]
        }
        
        // init code
        init(profile1: SHFWProfile, profile2: SHFWProfile, profile3: SHFWProfile) {
            self.profile1 = profile1
            self.profile2 = profile2
            self.profile3 = profile3
        }
        
        private var scooterManager: ScooterManager! = nil
        
        fileprivate func setScooterManager(_ scooterManager: ScooterManager) {
            self.scooterManager = scooterManager
        }
    }
    
    class SHFW : Observable {
        @Published fileprivate(set) var compatible: Bool? = nil
        @Published fileprivate(set) var installed: Bool? = nil
        @Published fileprivate(set) var version: SHFWVersion? = nil
        
        @Published private(set) var config: SHFWConfig? = nil
        
        // config init code
        fileprivate var initProfile1Core: SHFWMessage.ProfileData? = nil
        fileprivate var initProfile1Extra: SHFWMessage.ProfileExtraData? = nil
        fileprivate var initProfile2Core: SHFWMessage.ProfileData? = nil
        fileprivate var initProfile2Extra: SHFWMessage.ProfileExtraData? = nil
        fileprivate var initProfile3Core: SHFWMessage.ProfileData? = nil
        fileprivate var initProfile3Extra: SHFWMessage.ProfileExtraData? = nil
        fileprivate var settingsCore: SHFWMessage.SystemSettings? = nil
        fileprivate var settingsExtra: SHFWMessage.ExtraSystemSettings? = nil
        
        fileprivate func initConfig() {
            guard let initProfile1Core = initProfile1Core,
                  let initProfile1Extra = initProfile1Extra,
                  let initProfile2Core = initProfile2Core,
                  let initProfile2Extra = initProfile2Extra,
                  let initProfile3Core = initProfile3Core,
                  let initProfile3Extra = initProfile3Extra,
//                  let settingsCore = settingsCore,
//                  let settingsExtra = settingsExtra,
                  self.config == nil else {
                return
            }
            
            var profiles: [SHFWProfile] = []
            
            let profileData: [(SHFWMessage.ProfileData, SHFWMessage.ProfileExtraData)] = [
                (initProfile1Core, initProfile1Extra),
                (initProfile2Core, initProfile2Extra),
                (initProfile3Core, initProfile3Extra)
            ]
            
            for (profileNum, (pdc, pde)) in profileData.enumerated() {
                profiles.append(
                    .init(
                        profile: profileNum,
                        scooterManager: self.scooterManager,
                        ecoAmps: pdc.ecoAmps,
                        driveAmps: pdc.driveAmps,
                        sportsAmps: pdc.sportsAmps,
                        brakeAmps: pdc.brakeAmps,
                        ecoSmoothness: pdc.ecoSmoothness,
                        driveSmoothness: pdc.driveSmoothness,
                        sportsSmoothness: pdc.sportsSmoothness,
                        msp: pdc.msp,
                        brakeBoost: pdc.brakeBoost,
                        brakeLight: pdc.brakeLight,
                        booleans: pdc.booleans,
                        idleData: pdc.idleData,
                        speedData: pdc.speedData,
                        alternatingData: pdc.alternatingData,
                        batteryBarData: pdc.batteryBarData,
                        ccMode: pdc.ccMode,
                        ccEnterBeep: pdc.ccEnterBeep,
                        ccDelay: pdc.ccDelay,
                        ccExitBeep: pdc.ccExitBeep,
                        initMode: pdc.initMode,
                        initBeep: pdc.initBeep,
                        brakeMsp: pdc.brakeMsp,
                        brakeOvershoot: pdc.brakeOvershoot,
                        ccChangeTime: pdc.ccChangeTime,
                        autobrakeAmps: pdc.autobrakeAmps,
                        fwkSpeed: pde.fwkSpeed,
                        fwkCurrent: pde.fwkCurrent,
                        fwkVarCurrent: pde.fwkVarCurrent,
                        maxFieldCurrent: pde.maxFieldCurrent,
                        maxTorqueCurrent: pde.maxTorqueCurrent,
                        accelerationBoost: pde.accelerationBoost,
                        newBooleans: pde.booleans
                    )
                )
            }
            
            guard profiles.count == profileData.count else {
                fatalError("something went seriously wrong")
            }
            
            self.config = .init(
                profile1: profiles[0],
                profile2: profiles[1],
                profile3: profiles[2]
            )
        }
        
        // init code
        private var scooterManager: ScooterManager! = nil
        
        fileprivate func setScooterManager(_ scooterManager: ScooterManager) {
            self.scooterManager = scooterManager
        }
    }
    
    fileprivate var forceNbCrypto: Bool = false
    fileprivate var scooterBluetooth: ScooterBluetooth = .init()
    fileprivate var scooterCrypto: ScooterCrypto = .init()
    fileprivate var messageManager: RawMessageManager = .init(scooterProtocol: .ninebot(true))
    fileprivate var scooterRemover: [UUID: Timer] = [:]
    
    // used for ensuring only 1 info dump can run at any given time
    // (any more would be a waste of WriteLoop cycles)
    fileprivate var infoDumpId = 0
    
    @Published var discoveredScooters: OrderedDictionary<UUID, DiscoveredScooter> = [:]
    
    @Published var coreInfo: CoreInfo = .init()
    @Published var infoDump: StockNBMessage.InfoDump? = nil
    @Published var shfw: SHFW = .init()
    
    var authenticating: Bool = false
    var model: ScooterModel? = nil
    var connectionState: ConnectionState = .disconnected
    
    init() {
        self.scooterBluetooth.setScooterBluetoothDelegate(self)
        self.coreInfo.setScooterManager(self)
        self.shfw.setScooterManager(self)
    }
    
    // basic bluetooth methods
    func connectTo(discoveredScooter: DiscoveredScooter, forceNbCrypto: Bool = false) {
        let name = discoveredScooter.name
        let scooterProtocol = discoveredScooter.model.scooterProtocol(forceNbCrypto: forceNbCrypto)
        
        self.model = discoveredScooter.model
        self.forceNbCrypto = forceNbCrypto
        self.scooterCrypto.setName(name)
        self.scooterCrypto.setProtocol(scooterProtocol)
        self.messageManager = .init(scooterProtocol: scooterProtocol)
        scooterBluetooth.connect(discoveredScooter.peripheral, name: name, scooterProtocol: scooterProtocol)
    }
    
    // TODO: add "updateUi" back for miauth
    func disconnectFromScooter() {
        scooterBluetooth.disconnect(nil)
    }
    
    func writeRaw(_ data: Data?, characteristic: WriteLoop.WriteCharacteristic, writeType: WriteLoop.WriteType) {
        guard let data = data else {
            return
        }
        
        self.scooterBluetooth.write(writeType: writeType, characteristic: characteristic) {
            var data = data
            if characteristic == .serial, self.model?.scooterProtocol(forceNbCrypto: self.forceNbCrypto).crypto == true {
                data = self.scooterCrypto.encrypt(data)
            }
            return data
        }
    }
    
    // private stuff
    fileprivate func handle(_ message: ParsedNinebotMessage) {
        switch message {
        case let .stockNBMessage(message): self.handleStockNB(message)
        case let .shfwMessage(message): self.handleSHFW(message)
        default: break
        }
    }
    
    fileprivate func handleStockNB(_ message: StockNBMessage) {
        switch message {
        case let .serialNumber(serial): self.coreInfo.serial = serial
        case let .escVersion(version): self.coreInfo.esc = version
        case let .bleVersion(version): self.coreInfo.ble = version
        case let .bmsVersion(version): self.coreInfo.bms = version
        case let .infoDump(infoDump): self.infoDump = infoDump
        default: break
        }
    }
    
    fileprivate func handleSHFW(_ message: SHFWMessage) {
        // couldn't be bothered to figure out key paths for profiles
        switch message {
        case let .profileCore(profile, settings, _):
            switch profile {
            case 0: self.shfw.initProfile1Core = settings
            case 1: self.shfw.initProfile2Core = settings
            case 2: self.shfw.initProfile3Core = settings
            default: break
            }
            
            self.shfw.initConfig()
        case let .profileExtra(profile, settings, _):
            switch profile {
            case 0: self.shfw.initProfile1Extra = settings
            case 1: self.shfw.initProfile2Extra = settings
            case 2: self.shfw.initProfile3Extra = settings
            default: break
            }
            self.shfw.initConfig()
        case let .profileItem(profileNum, item):
            guard let profile = switch profileNum {
            case 0: self.shfw.config?.profile1
            case 1: self.shfw.config?.profile2
            case 2: self.shfw.config?.profile3
            default: nil
            } else {
                break
            }
            
            switch item {
            case let .ecoAmps(v0, v1, v2, v3): profile._ecoAmps = [v0, v1, v2, v3]; profile.ecoAmps.update()
            case let .ecoAmps1(v): profile._ecoAmps[0] = v; profile.ecoAmps.update()
            case let .ecoAmps2(v): profile._ecoAmps[1] = v; profile.ecoAmps.update()
            case let .ecoAmps3(v): profile._ecoAmps[2] = v; profile.ecoAmps.update()
            case let .ecoAmps4(v): profile._ecoAmps[3] = v; profile.ecoAmps.update()
            case let .driveAmps(v0, v1, v2, v3): profile._driveAmps = [v0, v1, v2, v3]; profile.driveAmps.update()
            case let .driveAmps1(v): profile._driveAmps[0] = v; profile.driveAmps.update()
            case let .driveAmps2(v): profile._driveAmps[1] = v; profile.driveAmps.update()
            case let .driveAmps3(v): profile._driveAmps[2] = v; profile.driveAmps.update()
            case let .driveAmps4(v): profile._driveAmps[3] = v; profile.driveAmps.update()
            case let .sportsAmps(v0, v1, v2, v3): 
                profile._sportsAmps = [v0, v1, v2, v3]
                profile.sportsAmps.update()
                print("updated")
            case let .sportsAmps1(v): profile._sportsAmps[0] = v; profile.sportsAmps.update()
            case let .sportsAmps2(v): profile._sportsAmps[1] = v; profile.sportsAmps.update()
            case let .sportsAmps3(v): profile._sportsAmps[2] = v; profile.sportsAmps.update()
            case let .sportsAmps4(v): profile._sportsAmps[3] = v; profile.sportsAmps.update()
            case let .brakeAmps(v0, v1, v2, v3): profile._brakeAmps = [v0, v1, v2, v3]; profile.brakeAmps.update()
            case let .brakeAmps1(v): profile._brakeAmps[0] = v; profile.brakeAmps.update()
            case let .brakeAmps2(v): profile._brakeAmps[1] = v; profile.brakeAmps.update()
            case let .brakeAmps3(v): profile._brakeAmps[2] = v; profile.brakeAmps.update()
            case let .brakeAmps4(v): profile._brakeAmps[3] = v; profile.brakeAmps.update()
            case let .ecoSmoothness(smooothness): profile._ecoSmoothness = smooothness; profile.ecoSmoothness.update()
            case let .driveSmoothness(smooothness): profile._driveSmoothness = smooothness; profile.driveSmoothness.update()
            case let .sportsSmoothness(smooothness): profile._sportsSmoothness = smooothness; profile.sportsSmoothness.update()
            case let .mspBrakeBoost(msp, brakeBoost):
                profile._msp = msp; profile.msp.update()
                profile._brakeBoost = brakeBoost; profile.brakeBoost.update()
            case let .brakeLight(config): profile._brakeLight = config; profile.brakeLight.update()
            case let .booleans(booleans): profile._booleans = booleans; profile.booleans.update()
            case let .idleSpeedData(idleData, speedData):
                profile._idleData = idleData; profile.idleData.update()
                profile._speedData = speedData; profile.speedData.update()
            case let .alternatingBatteryBarData(alternatingData, batteryBarData):
                profile._alternatingData = alternatingData; profile.alternatingData.update()
                profile._batteryBarData = batteryBarData; profile.batteryBarData.update()
            case let .ccModeBeep(mode, enterBeep):
                profile._ccMode = mode; profile.ccMode.update()
                profile._ccEnterBeep = enterBeep; profile.ccEnterBeep.update()
            case let .ccDelayExitBeep(delay, exitBeep):
                profile._ccDelay = delay; profile.ccDelay.update()
                profile._ccExitBeep = exitBeep; profile.ccExitBeep.update()
            case let .initModeBeep(mode, beep):
                profile._initMode = mode; profile.initMode.update()
                profile._initBeep = beep; profile.initBeep.update()
            case let .brakeMspOvershoot(msp, overshoot):
                profile._brakeMsp = msp; profile.brakeMsp.update()
                profile._brakeOvershoot = overshoot; profile.brakeOvershoot.update()
            case let .ccChangeTimeAutobrakingAmps(ccChangeTime, autobrakeAmps):
                profile._ccChangeTime = ccChangeTime; profile.ccChangeTime.update()
                profile._autobrakeAmps = autobrakeAmps; profile.autobrakeAmps.update()
            case let .fwkSpeedCurrent(speed, current):
                profile._fwkSpeed = speed; profile.fwkSpeed.update()
                profile._fwkCurrent = current; profile.fwkCurrent.update()
            case let .fwkVarCurrent(current): profile._fwkVarCurrent = current; profile.fwkVarCurrent.update()
            case let .maxFieldTorqueCurrent(field, torque):
                profile._maxFieldCurrent = field; profile.maxFieldCurrent.update()
                profile._maxTorqueCurrent = torque; profile.maxTorqueCurrent.update()
            case let .accelerationBoost(boost): profile._accelerationBoost = boost; profile.accelerationBoost.update()
            case let .newBooleans(booleans): profile._newBooleans = booleans; profile.newBooleans.update()
            }
        case let .systemSettings(settings, _): break
        case let .extraSystemSettings(settings, _): break
        case let .systemSetting(settings): break
        case let .version(version):
            guard !version.newVersioning else {
                let msg = self.messageManager.ninebotRead(SHFWMessage.newVersion())
                self.writeRaw(msg, characteristic: .serial, writeType: .conditionLimitTimes(
                    condition: {
                        self.shfw.version == nil
                    },
                    times: 10,
                    limitHit: {
                        print("[ScooterManager]", "version response indicates new versioning is used, but scooter refused to let us have it. pretending shfw not installed")
                        self.shfw.installed = false
                        self.shfw.compatible = true
                    }
                ))
                return
            }
            
            self.shfw.version = version
        case let .newVersion(version):
            self.shfw.version = version
            self.shfw.installed = true
            self.shfw.compatible = true
            
            // TODO: allow to compare shfw versions using operators and make sure running >= 3.9.1 or whatev
            let requests: [(NinebotMessage, () -> (Bool))] = [
                (SHFWMessage.profileCore(0), { self.shfw.initProfile1Core == nil }),
                (SHFWMessage.profileCore(1), { self.shfw.initProfile2Core == nil }),
                (SHFWMessage.profileCore(2), { self.shfw.initProfile3Core == nil }),
                (SHFWMessage.profileExtra(0), { self.shfw.initProfile1Extra == nil }),
                (SHFWMessage.profileExtra(1), { self.shfw.initProfile2Extra == nil }),
                (SHFWMessage.profileExtra(2), { self.shfw.initProfile3Extra == nil }),
            ]
            
            for (request, check) in requests {
                let msg = self.messageManager.ninebotRead(request)
                self.writeRaw(msg, characteristic: .serial, writeType: .condition(condition: check))
            }
        default: break
        }
    }
    
    fileprivate func startInfoDump() {
        self.infoDumpId += 1
        let newInfoDumpId = self.infoDumpId
        let infoDumpMsg = self.messageManager.ninebotRead(StockNBMessage.infoDump())
        self.writeRaw(infoDumpMsg, characteristic: .serial, writeType: .condition {
            self.infoDumpId == newInfoDumpId
        })
    }
    
    fileprivate func stopInfoDump() {
        self.infoDumpId += 1
    }
    
    fileprivate func requestAll() {
        self.requestCoreInfo()
        self.requestShfw()
    }
    
    fileprivate func requestCoreInfo() {
        let coreRequests: [(NinebotMessage, () -> (Bool))] = [
            (StockNBMessage.serialNumber(), { self.coreInfo.serial == nil }),
            (StockNBMessage.escVersion(), { self.coreInfo.esc == nil }),
            (StockNBMessage.bleVersion(), { self.coreInfo.ble == nil }),
            (StockNBMessage.bmsVersion(), { self.coreInfo.bms == nil })
        ]
        
        for (request, check) in coreRequests {
            let msg = self.messageManager.ninebotRead(request)
            self.writeRaw(msg, characteristic: .serial, writeType: .condition(condition: check))
        }
    }
    
    fileprivate func requestShfw() {
        let msg = self.messageManager.ninebotRead(SHFWMessage.version())
        self.writeRaw(msg, characteristic: .serial, writeType: .conditionLimitTimes(
            condition: {
                self.shfw.installed == nil
            },
            times: 10,
            limitHit: {
                self.shfw.installed = false
                // TODO: when SHFWApi is ready, set self.shfw.compatability to api's response
            }
        ))
    }
    
    // underlying ScooterBluetooth methods
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didDiscover scooter: DiscoveredScooter, forIdentifier identifier: UUID) {
        if let oldScooter = self.discoveredScooters[identifier] {
            if scooterCrypto.awaitingButtonPress && oldScooter.serviceData != scooter.serviceData {
                self.connectTo(discoveredScooter: scooter)
            }
        }
        
        self.discoveredScooters[identifier] = scooter
        self.scooterRemover[identifier]?.invalidate()
        self.scooterRemover[identifier] = Timer.scheduledTimer(withTimeInterval: advertisementTimeout, repeats: false) { _ in
            self.discoveredScooters.removeValue(forKey: identifier)
        }
    }
    
    func scooterBluetoothDidUpdateState(_ scooterBluetooth: ScooterBluetooth) {
        let connectionState = self.scooterBluetooth.connectionState
        self.connectionState = connectionState
        self.authenticating = self.authenticating || connectionState == .authenticating
        
        switch(connectionState) {
        case .disconnected:
            if !self.scooterBluetooth.blockDisconnectUpdates {
                self.authenticating = false
                self.model = nil
                self.connectionState = .disconnected
                
                self.scooterCrypto.reset()
            }
        case .ready:
            if !self.scooterCrypto.authenticated {
                self.scooterCrypto.startAuthenticating(withScooterManager: self)
            }
        case .connected:
            // TODO: start collecting info and whatnot
            self.startInfoDump()
            self.requestAll()
        default: return
        }
    }
    
    func scooterBluetooth(_ scooterBluetooth: ScooterBluetooth, didReceive data: Data, forCharacteristic uuid: CBUUID) {
        var data = data
        if uuid == serialRXCharUUID {
            guard let decryptedData = self.scooterCrypto.decrypt(data) else {
                return
            }
            data = decryptedData
        }
        
        if !self.scooterCrypto.authenticated {
            let connectionState = self.scooterCrypto.continueAuthenticating(withScooterManager: self, received: data, forCharacteristic: uuid)
            if let connectionState = connectionState {
                scooterBluetooth.setConnectionState(connectionState)
            }
            return
        }
        
        if let parsedData = self.messageManager.ninebotParse(data) {
            self.handle(parsedData)
        }
    }
}

