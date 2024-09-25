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
            requestMsg.write(ack: false),
            characteristic: .serial,
            writeType: .foreverLimitTimes(times: 2)
        )
        scooterManager.writeRaw(
            requestMsg.read(),
            characteristic: .serial,
            writeType: .foreverLimitTimes(times: 2)
        )
    })
}

class ScooterManager : ObservableObject, ScooterBluetoothDelegate {
    class CoreInfo : Observable {
        @State fileprivate(set) var serial: String? = nil
        @State fileprivate(set) var esc: NinebotVersion? = nil
        @State fileprivate(set) var ble: NinebotVersion? = nil
        @State fileprivate(set) var bms: NinebotVersion? = nil
        
        // init code
        private var scooterManager: ScooterManager! = nil
        
        fileprivate func setScooterManager(_ scooterManager: ScooterManager) {
            self.scooterManager = scooterManager
        }
    }
    
    class SHFWProfile : ObservableObject {
        fileprivate var _ecoAmps: [Float]!
        var ecoAmps: Binding<[Float]>!
        
        fileprivate var _driveAmps: [Float]!
        var driveAmps: Binding<[Float]>!

        fileprivate var _sportsAmps: [Float]!
        var sportsAmps: Binding<[Float]>!

        fileprivate var _brakeAmps: [Float]!
        var brakeAmps: Binding<[Float]>!

        fileprivate var _ecoSmoothness: SHFWMessage.SpeedBasedConfig!
        var ecoSmoothness: Binding<SHFWMessage.SpeedBasedConfig>!

        fileprivate var _driveSmoothness: SHFWMessage.SpeedBasedConfig!
        var driveSmoothness: Binding<SHFWMessage.SpeedBasedConfig>!

        fileprivate var _sportsSmoothness: SHFWMessage.SpeedBasedConfig!
        var sportsSmoothness: Binding<SHFWMessage.SpeedBasedConfig>!

        fileprivate var _msp: Int!
        var msp: Binding<Int>!

        fileprivate var _brakeBoost: Int!
        var brakeBoost: Binding<Int>!

        fileprivate var _brakeLight: SHFWMessage.BrakeLightConfig!
        var brakeLight: Binding<SHFWMessage.BrakeLightConfig>!

        fileprivate var _booleans: SHFWMessage.ProfileBoolean!
        var booleans: Binding<SHFWMessage.ProfileBoolean>!

        fileprivate var _idleData: SHFWMessage.DashData!
        var idleData: Binding<SHFWMessage.DashData>!

        fileprivate var _speedData: SHFWMessage.DashData!
        var speedData: Binding<SHFWMessage.DashData>!

        fileprivate var _alternatingData: SHFWMessage.DashData!
        var alternatingData: Binding<SHFWMessage.DashData>!

        fileprivate var _batteryBarData: SHFWMessage.BatteryBarData!
        var batteryBarData: Binding<SHFWMessage.BatteryBarData>!

        fileprivate var _ccMode: SHFWMessage.CCMode!
        var ccMode: Binding<SHFWMessage.CCMode>!

        fileprivate var _ccEnterBeep: SHFWMessage.Beep!
        var ccEnterBeep: Binding<SHFWMessage.Beep>!

        fileprivate var _ccDelay: Int!
        var ccDelay: Binding<Int>!

        fileprivate var _ccExitBeep: SHFWMessage.Beep!
        var ccExitBeep: Binding<SHFWMessage.Beep>!

        fileprivate var _initMode: SHFWMessage.DriveMode!
        var initMode: Binding<SHFWMessage.DriveMode>!

        fileprivate var _initBeep: SHFWMessage.Beep!
        var initBeep: Binding<SHFWMessage.Beep>!

        fileprivate var _brakeMsp: Int!
        var brakeMsp: Binding<Int>!

        fileprivate var _brakeOvershoot: Int!
        var brakeOvershoot: Binding<Int>!

        fileprivate var _ccChangeTime: Float!
        var ccChangeTime: Binding<Float>!

        fileprivate var _autobrakeAmps: Int!
        var autobrakeAmps: Binding<Int>!

        fileprivate var _fwkSpeed: Int!
        var fwkSpeed: Binding<Int>!

        fileprivate var _fwkCurrent: Int!
        var fwkCurrent: Binding<Int>!

        fileprivate var _fwkVarCurrent: Int!
        var fwkVarCurrent: Binding<Int>!

        fileprivate var _maxFieldCurrent: Int!
        var maxFieldCurrent: Binding<Int>!

        fileprivate var _maxTorqueCurrent: Int!
        var maxTorqueCurrent: Binding<Int>!

        fileprivate var _accelerationBoost: Int!
        var accelerationBoost: Binding<Int>!

        fileprivate var _newBooleans: SHFWMessage.NewProfileBoolean!
        var newBooleans: Binding<SHFWMessage.NewProfileBoolean>!
        
        init(
            profile: Int,
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
                
                return configBinding(scooterManager: self.scooterManager, getValue: { self[keyPath: valuePath] }) { newValue in
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
        
        // init code
        private var scooterManager: ScooterManager! = nil
        
        fileprivate func setScooterManager(_ scooterManager: ScooterManager) {
            self.scooterManager = scooterManager
        }
    }
    
    class SHFWConfig : Observable {
        @State fileprivate(set) var profile1: SHFWProfile
        @State fileprivate(set) var profile2: SHFWProfile
        @State fileprivate(set) var profile3: SHFWProfile
        
        // init code
        init(profile1: SHFWProfile, profile2: SHFWProfile, profile3: SHFWProfile) {
            self.profile1 = profile1
            self.profile2 = profile2
            self.profile3 = profile3
        }
        
        private var scooterManager: ScooterManager! = nil
        
        fileprivate func setScooterManager(_ scooterManager: ScooterManager) {
            self.scooterManager = scooterManager
            
            self.profile1.setScooterManager(scooterManager)
            self.profile2.setScooterManager(scooterManager)
            self.profile3.setScooterManager(scooterManager)
        }
    }
    
    class SHFW : Observable {
        @State fileprivate(set) var compatible: Bool? = nil
        @State fileprivate(set) var installed: Bool? = nil
        @State fileprivate(set) var version: SHFWVersion? = nil
        
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
                  let settingsCore = settingsCore,
                  let settingsExtra = settingsExtra else {
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
        // TODO: do something with the parsed data
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
        self.requestFullShfw()
    }
    
    fileprivate func requestCoreInfo() {
        let coreRequests: [(NinebotMessage, PartialKeyPath<CoreInfo>)] = [
            (StockNBMessage.serialNumber(), \CoreInfo.serial),
            (StockNBMessage.escVersion(), \CoreInfo.esc),
            (StockNBMessage.bleVersion(), \CoreInfo.ble),
            (StockNBMessage.bmsVersion(), \CoreInfo.bms)
        ]
        
        for (request, key) in coreRequests {
            let msg = self.messageManager.ninebotRead(request)
            self.writeRaw(msg, characteristic: .serial, writeType: .condition(
                condition: {
                    self.coreInfo[keyPath: key] as Optional == nil
                }
            ))
        }
    }
    
    fileprivate func requestFullShfw() {
        
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

