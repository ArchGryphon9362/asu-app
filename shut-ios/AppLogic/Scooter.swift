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
    
    var image: ImageResource {
        switch(self) {
        case .XiaomiPro2: return .xiaomiPro2
        }
    }
    
    var name: String {
        switch(self) {
        case .XiaomiPro2: "Mi Electric Scooter Pro 2"
        }
    }
    
    var auth: SelectedProtocol {
        switch(self) {
        case .XiaomiPro2: .xiaomiCrypto
        }
    }
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
    @Published var connectionState: ConnectionState
    
    init(_ scooterManager: ScooterManager) {
        self.scooterManager = scooterManager
        self.shfw = SHFW()
        self.connectionState = .disconnected
    }
    
    func reset() {
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
    
    func connect() {
        // TODO: implement
    }
}
