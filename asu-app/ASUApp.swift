//
//  ASUApp.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI

@main
struct ASUApp: App {
    let scooterManager: ScooterManager
    
    init() {
        self.scooterManager = ScooterManager()
    }
    
    var body: some Scene {
        WindowGroup {
            DiscoveryView()
                .environmentObject(scooterManager)
                .navigationTitle("Arch's Scooter Utility")
        }
    }
}