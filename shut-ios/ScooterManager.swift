//
//  ScooterManager.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation
import OrderedCollections

class ScooterManager : ObservableObject {
    @Published var discoveredScooters: OrderedDictionary<UUID, DiscoveredScooter>
    // I, Lex, solely acknowledge that my initializing method can be classed as "fucking unsafe",
    // I will proceed with care. :trollface:
    @Published var scooter: Scooter!
    @Published var scooterBluetooth: ScooterBluetooth!
    
    init() {
        self.discoveredScooters = [:]
        self.scooter = Scooter(self)
        self.scooterBluetooth = ScooterBluetooth(self)
    }
    
    func connectToScooter(scooter: DiscoveredScooter) {
        scooterBluetooth.connect(scooter.peripheral)
    }
    
    func disconncetFromScooter(scooter: DiscoveredScooter) {
        scooterBluetooth.disconnect(scooter.peripheral)
    }
}
