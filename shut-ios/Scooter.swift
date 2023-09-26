//
//  Scooter.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation

enum ScooterModel {
    case XiaomiPro2
}

class Scooter : ObservableObject {
    @Published private var scooterManager: ScooterManager!
    
    @Published var ble: String?
    @Published var esc: String?
    @Published var bms: String?
    @Published var serial: String?
    @Published var uuid: String?
    @Published var model: ScooterModel?
    @Published var battery: Int?
    @Published var shfw: SHFW
    var connectionState: ConnectionState {
        return scooterManager.scooterBluetooth.connectionState
    }
    
    init(_ scooterManager: ScooterManager) {
        self.scooterManager = scooterManager
        self.shfw = SHFW()
    }
    
    func connect() {
        // TODO: implement
    }
}
