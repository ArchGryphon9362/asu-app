// Thanks to Basse for providing the beacon parsing code and all the models
//
//  Scooter.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI

struct Scooter: Equatable {
    var authenticating: Bool
    
    var ble: String?
    var esc: String?
    var bms: String?
    var serial: String?
    var uuid: String?
    var model: ScooterModel?
    var infoDump: StockNBMessage.InfoDump?
    var shfw: SHFW
    var connectionState: ConnectionState
    
    init() {
        self.authenticating = false
        
        self.shfw = SHFW()
        self.connectionState = .disconnected
    }
    
    mutating func reset() {
        self.authenticating = false
        
        self.ble = nil
        self.esc = nil
        self.bms = nil
        self.serial = nil
        self.uuid = nil
        self.model = nil
        self.shfw = SHFW()
        self.connectionState = .disconnected
    }
}
