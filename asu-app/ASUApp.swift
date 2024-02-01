//
//  ASUApp.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI

// TODO: asu fox theme ;)
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
        #if os(macOS)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Settings") {
                    SettingsWindowController.shared.showWindow(nil)
                }.keyboardShortcut(",", modifiers: .command)
            }
        }
        #endif
    }
}
