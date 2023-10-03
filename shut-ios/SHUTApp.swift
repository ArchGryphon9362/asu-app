//
//  shut_iosApp.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI

@main
struct SHUTApp: App {
    let scooterManager: ScooterManager
    
    init() {
        self.scooterManager = ScooterManager()
    }
    
    var body: some Scene {
        WindowGroup {
            DiscoveryView()
                .environmentObject(scooterManager)
                .navigationTitle("Archs Scooter Utility")
        }
    }
}
