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

class ScooterManager : ObservableObject, ScooterBluetoothDelegate, Identifiable {
    class CoreInfo : ObservableObject, Identifiable {
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
    
    class InfoDump : ObservableObject, Identifiable {
        @Published var errorCode: StockNBMessage.ErrorCode? = nil
        @Published var alarmCode: StockNBMessage.AlarmCode? = nil
        @Published var scooterStatus: StockNBMessage.ScooterStatus? = nil
        @Published var bat1Pct: Float? = nil
        @Published var bat2Pct: Float? = nil
        @Published var chargePct: Float? = nil
        @Published var speed: Float? = nil
        @Published var averageSpeed: Float? = nil
        @Published var mileage: Float? = nil
        @Published var uptime: Int? = nil
        @Published var bodyTemp: Float? = nil
        @Published var speedLimit: Float? = nil
        @Published var wattage: Int? = nil
        @Published var predictedDistance: Float? = nil
        
        func newInfo(_ infoDump: StockNBMessage.InfoDump) {
            if self.errorCode != infoDump.errorCode { self.errorCode = infoDump.errorCode }
            if self.alarmCode != infoDump.alarmCode { self.alarmCode = infoDump.alarmCode }
            if self.scooterStatus != infoDump.scooterStatus { self.scooterStatus = infoDump.scooterStatus }
            if self.bat1Pct != infoDump.bat1Pct { self.bat1Pct = infoDump.bat1Pct }
            if self.bat2Pct != infoDump.bat2Pct { self.bat2Pct = infoDump.bat2Pct }
            if self.chargePct != infoDump.chargePct { self.chargePct = infoDump.chargePct }
            if self.speed != infoDump.speed { self.speed = infoDump.speed }
            if self.averageSpeed != infoDump.averageSpeed { self.averageSpeed = infoDump.averageSpeed }
            if self.mileage != infoDump.mileage { self.mileage = infoDump.mileage }
            if self.uptime != infoDump.uptime { self.uptime = infoDump.uptime }
            if self.bodyTemp != infoDump.bodyTemp { self.bodyTemp = infoDump.bodyTemp }
            if self.speedLimit != infoDump.speedLimit { self.speedLimit = infoDump.speedLimit }
            if self.wattage != infoDump.wattage { self.wattage = infoDump.wattage }
            if self.predictedDistance != infoDump.predictedDistance { self.predictedDistance = infoDump.predictedDistance }
        }
    }
    
    class SHFWProfile : ObservableObject, Identifiable {
        @Published var ecoAmps: [Float] {
            didSet { upd(\.ecoAmps, c: { v in v.count >= 4 }, { v in .ecoAmps(v[0], v[1], v[2], v[3]) }) }
        }
        
        // ######## //
        
        @Published var driveAmps: [Float] {
            didSet { upd(\.driveAmps, c: { v in v.count >= 4 }, { v in .driveAmps(v[0], v[1], v[2], v[3]) }) }
        }
        
        // ######## //

        @Published var sportsAmps: [Float] {
            didSet { upd(\.sportsAmps, c: { v in v.count >= 4 }, { v in .sportsAmps(v[0], v[1], v[2], v[3]) }) }
        }
        
        // ######## //

        @Published var brakeAmps: [Float] {
            didSet { upd(\.brakeAmps, c: { v in v.count >= 4 }, { v in .brakeAmps(v[0], v[1], v[2], v[3]) }) }
        }
        
        // ######## //

        @Published var ecoSmoothness: SHFWMessage.SpeedBasedConfig {
            didSet { upd(\.ecoSmoothness, { v in .ecoSmoothness(v) }) }
        }
        
        // ######## //

        @Published var driveSmoothness: SHFWMessage.SpeedBasedConfig {
            didSet { upd(\.driveSmoothness, { v in .driveSmoothness(v) }) }
        }
        
        // ######## //

        @Published var sportsSmoothness: SHFWMessage.SpeedBasedConfig {
            didSet { upd(\.sportsSmoothness, { v in .sportsSmoothness(v) }) }
        }
        
        // ######## //

        @Published var msp: Int {
            didSet { upd(\.msp, { v in .mspBrakeBoost(v, self.brakeBoost) }) }
        }
        
        @Published var brakeBoost: Int {
            didSet { upd(\.brakeBoost, { v in .mspBrakeBoost(self.msp, v) }) }
        }
        
        // ######## //

        @Published var brakeLight: SHFWMessage.BrakeLightConfig {
            didSet { upd(\.brakeLight, { v in .brakeLight(v) }) }
        }
        
        // ######## //

        @Published var booleans: SHFWMessage.ProfileBoolean {
            didSet { upd(\.booleans, { v in .booleans(v) }) }
        }
        
        // ######## //

        @Published var idleData: SHFWMessage.DashData {
            didSet { upd(\.idleData, { v in .idleSpeedData(v, self.speedData) }) }
        }

        @Published var speedData: SHFWMessage.DashData {
            didSet { upd(\.speedData, { v in .idleSpeedData(self.idleData, v) }) }
        }
        
        // ######## //

        @Published var alternatingData: SHFWMessage.DashData {
            didSet { upd(\.alternatingData, { v in .alternatingBatteryBarData(v, self.batteryBarData) }) }
        }

        @Published var batteryBarData: SHFWMessage.BatteryBarData {
            didSet { upd(\.batteryBarData, { v in .alternatingBatteryBarData(self.alternatingData, v) }) }
        }
        
        // ######## //

        @Published var ccMode: SHFWMessage.CCMode {
            didSet { upd(\.ccMode, { v in .ccModeBeep(v, self.ccEnterBeep) }) }
        }

        @Published var ccEnterBeep: SHFWMessage.Beep {
            didSet { upd(\.ccEnterBeep, { v in .ccModeBeep(self.ccMode, v) }) }
        }
        
        // ######## //

        @Published var ccDelay: Int {
            didSet { upd(\.ccDelay, { v in .ccDelayExitBeep(v, self.ccExitBeep) }) }
        }

        @Published var ccExitBeep: SHFWMessage.Beep {
            didSet { upd(\.ccExitBeep, { v in .ccDelayExitBeep(self.ccDelay, v) }) }
        }
        
        // ######## //

        @Published var initMode: SHFWMessage.DriveMode {
            didSet { upd(\.initMode, { v in .initModeBeep(v, self.initBeep) }) }
        }

        @Published var initBeep: SHFWMessage.Beep {
            didSet { upd(\.initBeep, { v in .initModeBeep(self.initMode, v) }) }
        }
        
        // ######## //

        @Published var brakeMsp: Int {
            didSet { upd(\.brakeMsp, { v in .brakeMspOvershoot(v, self.brakeOvershoot) }) }
        }

        @Published var brakeOvershoot: Int {
            didSet { upd(\.brakeOvershoot, { v in .brakeMspOvershoot(self.brakeMsp, v) }) }
        }
        
        // ######## //

        @Published var ccChangeTime: Float {
            didSet { upd(\.ccChangeTime, { v in .ccChangeTimeAutobrakingAmps(v, self.autobrakeAmps) }) }
        }

        @Published var autobrakeAmps: Int {
            didSet { upd(\.autobrakeAmps, { v in .ccChangeTimeAutobrakingAmps(self.ccChangeTime, v) }) }
        }
        
        // ######## //

        @Published var fwkSpeed: Int {
            didSet { upd(\.fwkSpeed, { v in .fwkSpeedCurrent(v, self.fwkCurrent) }) }
        }

        @Published var fwkCurrent: Int {
            didSet { upd(\.fwkCurrent, { v in .fwkSpeedCurrent(self.fwkSpeed, v) }) }
        }
        
        // ######## //

        @Published var fwkVarCurrent: Int {
            didSet { upd(\.fwkVarCurrent, { v in .fwkVarCurrent(v) }) }
        }
        
        // ######## //

        @Published var maxFieldCurrent: Int {
            didSet { upd(\.maxFieldCurrent, { v in .maxFieldTorqueCurrent(v, self.maxTorqueCurrent) }) }
        }

        @Published var maxTorqueCurrent: Int {
            didSet { upd(\.maxTorqueCurrent, { v in .maxFieldTorqueCurrent(self.maxFieldCurrent, v) }) }
        }
        
        // ######## //

        @Published var accelerationBoost: Int {
            didSet { upd(\.accelerationBoost, { v in .accelerationBoost(v) }) }
        }
        
        // ######## //

        @Published var newBooleans: SHFWMessage.NewProfileBoolean {
            didSet { upd(\.newBooleans, { v in .newBooleans(v) }) }
        }
        
        // ######## //

        private var profile: Int
        private var scooterManager: ScooterManager
        private var updateQueue: DispatchQueue
        private var syncing = false
        
        private func upd<T>(
            _ path: KeyPath<SHFWProfile, T>,
            c condition: @escaping (T) -> (Bool) = { _ in true },
            _ request: @escaping (T) -> (SHFWMessage.ProfileData.ProfileItem?)
        ) {
            guard !syncing, let profileMsg = request(self[keyPath: path]) else {
                return
            }
            
            let requestMsg = SHFWMessage.profileItem(self.profile, profileMsg)
            
            // TODO: read following:
            //       implement a `.after()` function for my WriteLoop yet that I can have
            //       schedule a new write only after all writes for a certain write have
            //       fired. this will need to be implemented under `WriteType.Limit`; this
            //       will pretty much be a prettier way of scheduling writes instead of
            //       having to abuse `limitHit` (which is there really of detecting condition
            //       exhaustion)
            guard
                let writeData = self.scooterManager.messageManager.ninebotWrite(requestMsg, ack: false),
                let readData  = self.scooterManager.messageManager.ninebotRead(requestMsg) else {
                return
            }
            
            self.scooterManager.writeRaw(writeData, characteristic: .serial, writeType: .conditionLimitTimes(
                condition: { return true },
                times: 2,
                limitHit: {
                    self.scooterManager.writeRaw(readData, characteristic: .serial, writeType: .foreverLimitTimes(times: 2))
                }
            ))
        }
        
        fileprivate func sync<T: Equatable>(_ path: ReferenceWritableKeyPath<SHFWProfile, T>, _ value: T) {
            self.updateQueue.async {
                self.syncing = true
                DispatchQueue.main.sync {
                    if self[keyPath: path] != value {
                        self[keyPath: path] = value
                    }
                    self.syncing = false
                }
            }
        }
        
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
            self.profile = profile
            self.scooterManager = scooterManager
            self.updateQueue = DispatchQueue(label: "dev.nyaaa.asu.sm.profile.queue.\(profile)", qos: .userInitiated)
            
            self.ecoAmps = ecoAmps
            self.driveAmps = driveAmps
            self.sportsAmps = sportsAmps
            self.brakeAmps = brakeAmps
            self.ecoSmoothness = ecoSmoothness
            self.driveSmoothness = driveSmoothness
            self.sportsSmoothness = sportsSmoothness
            self.msp = msp
            self.brakeBoost = brakeBoost
            self.brakeLight = brakeLight
            self.booleans = booleans
            self.idleData = idleData
            self.speedData = speedData
            self.alternatingData = alternatingData
            self.batteryBarData = batteryBarData
            self.ccMode = ccMode
            self.ccEnterBeep = ccEnterBeep
            self.ccDelay = ccDelay
            self.ccExitBeep = ccExitBeep
            self.initMode = initMode
            self.initBeep = initBeep
            self.brakeMsp = brakeMsp
            self.brakeOvershoot = brakeOvershoot
            self.ccChangeTime = ccChangeTime
            self.autobrakeAmps = autobrakeAmps
            self.fwkSpeed = fwkSpeed
            self.fwkCurrent = fwkCurrent
            self.fwkVarCurrent = fwkVarCurrent
            self.maxFieldCurrent = maxFieldCurrent
            self.maxTorqueCurrent = maxTorqueCurrent
            self.accelerationBoost = accelerationBoost
            self.newBooleans = newBooleans
        }
    }
    
    class SHFWGlobal : ObservableObject, Identifiable {
        @Published var activeProfile: Int {
            didSet { upd(\.activeProfile, { v in .activeProfile(v) }) }
        }
        
        // ######## //
        
        @Published var defaultProfile: Int {
            didSet { upd(\.defaultProfile, { v in .defaultProfile(v) }) }
        }
        
        // ######## //
        
        @Published var brakeProfile: Int {
            didSet { upd(\.brakeProfile, { v in .brakeProfile(v) }) }
        }
        
        // ######## //
        
        @Published var throttleProfile: Int {
            didSet { upd(\.throttleProfile, { v in .throttleProfile(v) }) }
        }
        
        // ######## //
        
        @Published var brakeThrottleBootProfile: Int {
            didSet { upd(\.brakeThrottleBootProfile, { v in .brakeThrottleBootProfile(v) }) }
        }
        
        // ######## //
        
        @Published var brakeButtonProfile: Int {
            didSet { upd(\.brakeButtonProfile, { v in .brakeButtonProfile(v) }) }
        }
        
        // ######## //
        
        @Published var brakeDoubleButtonProfile: Int {
            didSet { upd(\.brakeDoubleButtonProfile, { v in .brakeDoubleButtonProfile(v) }) }
        }
        
        // ######## //
        
        @Published var brakeThrottleProfile: Int {
            didSet { upd(\.brakeThrottleProfile, { v in .brakeThrottleProfile(v) }) }
        }
        
        // ######## //
        
        @Published var sequenceProfile: Int {
            didSet { upd(\.sequenceProfile, { v in .sequenceProfile(v, self.sequenceProfileData) }) }
        }
        
        @Published var sequenceProfileData: SHFWMessage.ProfileSequence {
            didSet { upd(\.sequenceProfileData, { v in .sequenceProfile(self.sequenceProfile, v) }) }
        }
        
        // ######## //
        
        @Published var pwm: Int {
            didSet { upd(\.pwm, { v in .pwm(v) }) }
        }
        
        // ######## //
        
        @Published var pidKd: Int {
            didSet { upd(\.pidKd, { v in .pidKdLowerLimit(v, self.pidLowerLimit) }) }
        }
        
        @Published var pidLowerLimit: Int {
            didSet { upd(\.pidLowerLimit, { v in .pidKdLowerLimit(self.pidKd, v) }) }
        }
        
        // ######## //
        
        @Published var pidKp: Int {
            didSet { upd(\.pidKp, { v in .pidKpKi(v, self.pidKi) }) }
        }
        
        @Published var pidKi: Int {
            didSet { upd(\.pidKi, { v in .pidKpKi(self.pidKp, v) }) }
        }
        
        // ######## //
        
        @Published var minThrottle: Int {
            didSet { upd(\.minThrottle, { v in .minMaxThrottle(v, self.maxThrottle) }) }
        }
        
        @Published var maxThrottle: Int {
            didSet { upd(\.maxThrottle, { v in .minMaxThrottle(self.minThrottle, v) }) }
        }
        
        // ######## //
        
        @Published var minBrake: Int {
            didSet { upd(\.minBrake, { v in .minMaxBrake(v, self.maxBrake) }) }
        }
        
        @Published var maxBrake: Int {
            didSet { upd(\.maxBrake, { v in .minMaxBrake(self.minBrake, v) }) }
        }
        
        // ######## //
        
        @Published var taillightBrightness: Int {
            didSet { upd(\.taillightBrightness, { v in .taillightBrightness(v) }) }
        }
        
        // ######## //
        
        @Published var idleTimeout: Int {
            didSet { upd(\.idleTimeout, { v in .idleTimeout(v) }) }
        }
        
        // ######## //
        
        @Published var lockedTimeout: Int {
            didSet { upd(\.lockedTimeout, { v in .lockedTimeout(v) }) }
        }
        
        // ######## //
        
        @Published var wheelSize: Float {
            didSet { upd(\.wheelSize, { v in .wheelSize(v) }) }
        }
        
        // ######## //
        
        @Published var bmsEmuSeries: SHFWMessage.BMSEmuSeries {
            didSet { upd(\.bmsEmuSeries, { v in .bmsEmuSeries(v) }) }
        }
        
        // ######## //
        
        @Published var bmsEmuAdc: Float {
            didSet { upd(\.bmsEmuAdc, { v in .bmsEmuAdc(v) }) }
        }
        
        // ######## //
        
        @Published var bmsEmuCapacity: Int {
            didSet { upd(\.bmsEmuCapacity, { v in .bmsEmuCapacity(v) }) }
        }
        
        // ######## //
        
        @Published var bmsEmuMinCell: Float {
            didSet { upd(\.bmsEmuMinCell, { v in .bmsEmuMinMaxCell(v, self.bmsEmuMinCell) }) }
        }
        
        @Published var bmsEmuMaxCell: Float {
            didSet { upd(\.bmsEmuMaxCell, { v in .bmsEmuMinMaxCell(self.bmsEmuMaxCell, v) }) }
        }
        
        // ######## //
        
        @Published var booleans: SHFWMessage.GlobalBoolean {
            didSet { upd(\.booleans, { v in .booleans(v) }) }
        }
        
        // ######## //
        
        private var scooterManager: ScooterManager
        private var updateQueue: DispatchQueue
        private var syncing = false
        
        private func upd<T>(
            _ path: KeyPath<SHFWGlobal, T>,
            c condition: @escaping (T) -> (Bool) = { _ in true },
            _ request: @escaping (T) -> (SHFWMessage.SystemSettings.Setting?)
        ) {
            guard let settingMsg = request(self[keyPath: path]) else {
                return
            }
            
            let requestMsg = SHFWMessage.systemSetting(settingMsg)
            
            // TODO: read following:
            //       implement a `.after()` function for my WriteLoop yet that I can have
            //       schedule a new write only after all writes for a certain write have
            //       fired. this will need to be implemented under `WriteType.Limit`; this
            //       will pretty much be a prettier way of scheduling writes instead of
            //       having to abuse `limitHit` (which is there really of detecting condition
            //       exhaustion)
            guard
                let writeData = self.scooterManager.messageManager.ninebotWrite(requestMsg, ack: false),
                let readData  = self.scooterManager.messageManager.ninebotRead(requestMsg) else {
                return
            }
            
            self.scooterManager.writeRaw(writeData, characteristic: .serial, writeType: .conditionLimitTimes(
                condition: { return true },
                times: 2,
                limitHit: {
                    self.scooterManager.writeRaw(readData, characteristic: .serial, writeType: .foreverLimitTimes(times: 2))
                }
            ))
        }
        
        fileprivate func sync<T: Equatable>(_ path: ReferenceWritableKeyPath<SHFWGlobal, T>, _ value: T) {
            self.updateQueue.async {
                self.syncing = true
                DispatchQueue.main.sync {
                    if self[keyPath: path] != value {
                        self[keyPath: path] = value
                    }
                    self.syncing = false
                }
            }
        }
        
        init(
            scooterManager: ScooterManager,
            activeProfile: Int,
            defaultProfile: Int,
            brakeProfile: Int,
            throttleProfile: Int,
            brakeThrottleBootProfile: Int,
            brakeButtonProfile: Int,
            brakeDoubleButtonProfile: Int,
            brakeThrottleProfile: Int,
            sequenceProfile: Int,
            sequenceProfileData: SHFWMessage.ProfileSequence,
            pwm: Int,
            pidKd: Int,
            pidLowerLimit: Int,
            pidKp: Int,
            pidKi: Int,
            minThrottle: Int,
            maxThrottle: Int,
            minBrake: Int,
            maxBrake: Int,
            taillightBrightness: Int,
            idleTimeout: Int,
            lockedTimeout: Int,
            wheelSize: Float,
            bmsEmuSeries: SHFWMessage.BMSEmuSeries,
            bmsEmuAdc: Float,
            bmsEmuCapacity: Int,
            bmsEmuMinCell: Float,
            bmsEmuMaxCell: Float,
            booleans: SHFWMessage.GlobalBoolean
        ) {
            self.scooterManager = scooterManager
            self.updateQueue = DispatchQueue(label: "dev.nyaaa.asu.sm.global.queue", qos: .userInitiated)
            
            self.activeProfile = activeProfile
            self.defaultProfile = defaultProfile
            self.brakeProfile = brakeProfile
            self.throttleProfile = throttleProfile
            self.brakeThrottleBootProfile = brakeThrottleBootProfile
            self.brakeButtonProfile = brakeButtonProfile
            self.brakeDoubleButtonProfile = brakeDoubleButtonProfile
            self.brakeThrottleProfile = brakeThrottleProfile
            self.sequenceProfile = sequenceProfile
            self.sequenceProfileData = sequenceProfileData
            self.pwm = pwm
            self.pidKd = pidKd
            self.pidLowerLimit = pidLowerLimit
            self.pidKp = pidKp
            self.pidKi = pidKi
            self.minThrottle = minThrottle
            self.maxThrottle = maxThrottle
            self.minBrake = minBrake
            self.maxBrake = maxBrake
            self.taillightBrightness = taillightBrightness
            self.idleTimeout = idleTimeout
            self.lockedTimeout = lockedTimeout
            self.wheelSize = wheelSize
            self.bmsEmuSeries = bmsEmuSeries
            self.bmsEmuAdc = bmsEmuAdc
            self.bmsEmuCapacity = bmsEmuCapacity
            self.bmsEmuMinCell = bmsEmuMinCell
            self.bmsEmuMaxCell = bmsEmuMaxCell
            self.booleans = booleans
        }
    }
    
    class SHFWConfig : ObservableObject, Identifiable {
        @Published var profile1: SHFWProfile
        @Published var profile2: SHFWProfile
        @Published var profile3: SHFWProfile
        @Published var global: SHFWGlobal
        
        func getProfile(_ profile: Int) -> SHFWProfile {
            return [self.profile1, self.profile2, self.profile3][profile]
        }
        
        // init code
        init(
            profile1: SHFWProfile,
            profile2: SHFWProfile,
            profile3: SHFWProfile,
            global: SHFWGlobal
        ) {
            self.profile1 = profile1
            self.profile2 = profile2
            self.profile3 = profile3
            self.global = global
        }
        
        private var scooterManager: ScooterManager! = nil
        
        fileprivate func setScooterManager(_ scooterManager: ScooterManager) {
            self.scooterManager = scooterManager
        }
    }
    
    class SHFW : ObservableObject, Identifiable {
        @Published fileprivate(set) var compatible: Bool? = nil
        @Published fileprivate(set) var installed: Bool? = nil
        @Published fileprivate(set) var version: SHFWVersion? = nil
        
        @Published var config: SHFWConfig? = nil
        
        // config init code
        fileprivate var initProfile1Core: SHFWMessage.ProfileData? = nil
        fileprivate var initProfile1Extra: SHFWMessage.ProfileExtraData? = nil
        fileprivate var initProfile2Core: SHFWMessage.ProfileData? = nil
        fileprivate var initProfile2Extra: SHFWMessage.ProfileExtraData? = nil
        fileprivate var initProfile3Core: SHFWMessage.ProfileData? = nil
        fileprivate var initProfile3Extra: SHFWMessage.ProfileExtraData? = nil
        fileprivate var initSettingsCore: SHFWMessage.SystemSettings? = nil
        fileprivate var initSettingsExtra: SHFWMessage.ExtraSystemSettings? = nil
        
        fileprivate func initConfig() {
            guard let initProfile1Core = initProfile1Core,
                  let initProfile1Extra = initProfile1Extra,
                  let initProfile2Core = initProfile2Core,
                  let initProfile2Extra = initProfile2Extra,
                  let initProfile3Core = initProfile3Core,
                  let initProfile3Extra = initProfile3Extra,
                  let sc = initSettingsCore,
                  let se = initSettingsExtra,
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
            
            let global = SHFWGlobal(
                scooterManager: self.scooterManager,
                activeProfile: sc.activeProfile,
                defaultProfile: sc.defaultProfile,
                brakeProfile: sc.brakeProfile,
                throttleProfile: sc.throttleProfile,
                brakeThrottleBootProfile: sc.brakeThrottleBootProfile,
                brakeButtonProfile: sc.brakeButtonProfile,
                brakeDoubleButtonProfile: sc.brakeDoubleButtonProfile,
                brakeThrottleProfile: sc.brakeThrottleProfile,
                sequenceProfile: sc.sequenceProfile,
                sequenceProfileData: sc.sequenceProfileData,
                pwm: se.pwm,
                pidKd: se.pidKd,
                pidLowerLimit: se.pidLowerLimit,
                pidKp: se.pidKp,
                pidKi: se.pidKi,
                minThrottle: se.minThrottle,
                maxThrottle: se.maxThrottle,
                minBrake: se.minBrake,
                maxBrake: se.maxBrake,
                taillightBrightness: se.taillightBrightness,
                idleTimeout: se.idleTimeout,
                lockedTimeout: se.lockedTimeout,
                wheelSize: se.wheelSize,
                bmsEmuSeries: se.bmsEmuSeries,
                bmsEmuAdc: se.bmsEmuAdc,
                bmsEmuCapacity: se.bmsEmuCapacity,
                bmsEmuMinCell: se.bmsEmuMinCell,
                bmsEmuMaxCell: se.bmsEmuMaxCell,
                booleans: se.booleans
            )
            
            self.config = .init(
                profile1: profiles[0],
                profile2: profiles[1],
                profile3: profiles[2],
                global: global
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
    @Published var infoDump: InfoDump = .init()
    @Published var shfw: SHFW = .init()
    
    @Published var authenticating: Bool = false
    @Published var model: ScooterModel? = nil
    @Published var connectionState: ConnectionState = .disconnected
    
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
        case let .infoDump(infoDump): self.infoDump.newInfo(infoDump)
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
            case let .ecoAmps(v0, v1, v2, v3): profile.sync(\.ecoAmps, [v0, v1, v2, v3])
            case let .driveAmps(v0, v1, v2, v3): profile.sync(\.driveAmps, [v0, v1, v2, v3])
            case let .sportsAmps(v0, v1, v2, v3): profile.sync(\.sportsAmps, [v0, v1, v2, v3])
            case let .brakeAmps(v0, v1, v2, v3): profile.sync(\.brakeAmps, [v0, v1, v2, v3])
            case let .ecoSmoothness(smooothness): profile.sync(\.ecoSmoothness, smooothness)
            case let .driveSmoothness(smooothness): profile.sync(\.driveSmoothness, smooothness)
            case let .sportsSmoothness(smooothness): profile.sync(\.sportsSmoothness, smooothness)
            case let .mspBrakeBoost(msp, brakeBoost):
                profile.sync(\.msp, msp)
                profile.sync(\.brakeBoost, brakeBoost)
            case let .brakeLight(config): profile.sync(\.brakeLight, config)
            case let .booleans(booleans): profile.sync(\.booleans, booleans)
            case let .idleSpeedData(idleData, speedData):
                profile.sync(\.idleData, idleData)
                profile.sync(\.speedData, speedData)
            case let .alternatingBatteryBarData(alternatingData, batteryBarData):
                profile.sync(\.alternatingData, alternatingData)
                profile.sync(\.batteryBarData, batteryBarData)
            case let .ccModeBeep(mode, enterBeep):
                profile.sync(\.ccMode, mode)
                profile.sync(\.ccEnterBeep, enterBeep)
            case let .ccDelayExitBeep(delay, exitBeep):
                profile.sync(\.ccDelay, delay)
                profile.sync(\.ccExitBeep, exitBeep)
            case let .initModeBeep(mode, beep):
                profile.sync(\.initMode, mode)
                profile.sync(\.initBeep, beep)
            case let .brakeMspOvershoot(msp, overshoot):
                profile.sync(\.brakeMsp, msp)
                profile.sync(\.brakeOvershoot, overshoot)
            case let .ccChangeTimeAutobrakingAmps(ccChangeTime, autobrakeAmps):
                profile.sync(\.ccChangeTime, ccChangeTime)
                profile.sync(\.autobrakeAmps, autobrakeAmps)
            case let .fwkSpeedCurrent(speed, current):
                profile.sync(\.fwkSpeed, speed)
                profile.sync(\.fwkCurrent, current)
            case let .fwkVarCurrent(current): profile.sync(\.fwkVarCurrent, current)
            case let .maxFieldTorqueCurrent(field, torque):
                profile.sync(\.maxFieldCurrent, field)
                profile.sync(\.maxTorqueCurrent, torque)
            case let .accelerationBoost(boost): profile.sync(\.accelerationBoost, boost)
            case let .newBooleans(booleans): profile.sync(\.newBooleans, booleans)
                
            // these are ignored because i currently have no way of setting individual amps without writing the whole thing.
            // in fact i REALLY should just remove individual reads/writes for these. it serves little to no purpose
            case .ecoAmps1, .driveAmps1, .sportsAmps1, .brakeAmps1: break
            case .ecoAmps2, .driveAmps2, .sportsAmps2, .brakeAmps2: break
            case .ecoAmps3, .driveAmps3, .sportsAmps3, .brakeAmps3: break
            case .ecoAmps4, .driveAmps4, .sportsAmps4, .brakeAmps4: break
            }
        case let .systemSettings(settings, _):
            self.shfw.initSettingsCore = settings
            self.shfw.initConfig()
        case let .extraSystemSettings(settings, _):
            self.shfw.initSettingsExtra = settings
            self.shfw.initConfig()
        case let .systemSetting(setting):
            guard let settings = self.shfw.config?.global else {
                return
            }
            
            switch setting {
            case let .activeProfile(profile): settings.sync(\.activeProfile, profile)
            case let .defaultProfile(profile): settings.sync(\.defaultProfile, profile)
            case let .brakeProfile(profile): settings.sync(\.brakeProfile, profile)
            case let .throttleProfile(profile): settings.sync(\.throttleProfile, profile)
            case let .brakeThrottleBootProfile(profile): settings.sync(\.brakeThrottleBootProfile, profile)
            case let .brakeButtonProfile(profile): settings.sync(\.brakeButtonProfile, profile)
            case let .brakeDoubleButtonProfile(profile): settings.sync(\.brakeDoubleButtonProfile, profile)
            case let .brakeThrottleProfile(profile): settings.sync(\.brakeThrottleProfile, profile)
            case let .sequenceProfile(profile, data):
                settings.sync(\.sequenceProfile, profile)
                settings.sync(\.sequenceProfileData, data)
            case let .pwm(pwm): settings.sync(\.pwm, pwm)
            case let .pidKdLowerLimit(kd, lowerLimit):
                settings.sync(\.pidKd, kd)
                settings.sync(\.pidLowerLimit, lowerLimit)
            case let .pidKpKi(kp, ki):
                settings.sync(\.pidKp, kp)
                settings.sync(\.pidKi, ki)
            case let .minMaxBrake(min, max):
                settings.sync(\.minBrake, min)
                settings.sync(\.maxBrake, max)
            case let .minMaxThrottle(min, max):
                settings.sync(\.minThrottle, min)
                settings.sync(\.maxThrottle, max)
            case let .taillightBrightness(brightness): settings.sync(\.taillightBrightness, brightness)
            case let .idleTimeout(timeout): settings.sync(\.idleTimeout, timeout)
            case let .lockedTimeout(timeout): settings.sync(\.lockedTimeout, timeout)
            case let .wheelSize(size): settings.sync(\.wheelSize, size)
            case let .bmsEmuSeries(series): settings.sync(\.bmsEmuSeries, series)
            case let .bmsEmuAdc(adc): settings.sync(\.bmsEmuAdc, adc)
            case let .bmsEmuCapacity(capacity): settings.sync(\.bmsEmuCapacity, capacity)
            case let .bmsEmuMinMaxCell(min, max):
                settings.sync(\.bmsEmuMinCell, min)
                settings.sync(\.bmsEmuMaxCell, max)
            case let .booleans(booleans): settings.sync(\.booleans, booleans)
            }
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
            self.shfw.installed = true
            self.shfw.compatible = true
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
                (SHFWMessage.systemSettings(), { self.shfw.initSettingsCore == nil }),
                (SHFWMessage.extraSystemSettings(), { self.shfw.initSettingsExtra == nil })
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
        if msg == nil {
            // if this is null, stub is most likely being used (or I fucked
            // something up elsewhere)
            self.shfw.installed = false
        }
        self.writeRaw(msg, characteristic: .serial, writeType: .conditionLimitTimes(
            condition: {
                return self.shfw.installed == nil
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
                
                self.coreInfo = .init()
                self.shfw = .init()
                self.coreInfo.setScooterManager(self)
                self.shfw.setScooterManager(self)
                
                self.infoDumpId = 0
                self.infoDump = .init()
            }
        case .ready:
            if !self.scooterCrypto.authenticated {
                self.scooterCrypto.startAuthenticating(withScooterManager: self)
            }
        case .connected:
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

