//
//  shut_iosApp.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI

@main
struct shut_iosApp: App {
    let scooterManager: ScooterManager
    
    init() {
        self.scooterManager = ScooterManager()
        
        let scooters = scooterManager.discoverScooters()
        // TODO: put this in the correct place
        scooters[UUID()]?.connect()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scooterManager.scooter)
        }
    }
}
