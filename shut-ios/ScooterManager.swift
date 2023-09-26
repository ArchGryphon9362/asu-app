//
//  ScooterManager.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation

class ScooterManager : ObservableObject {
    var scooter: Scooter!
    @Published var scooterBluetooth: ScooterBluetooth!
    
    init() {
        self.scooter = Scooter(self)
        self.scooterBluetooth = ScooterBluetooth(self)
    }
    
    func discoverScooters() -> [UUID: Scooter] {
        // TODO: implement
        return [:];
    }
}
