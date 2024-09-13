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
    let appManager: AppManager
    
    init() {
        self.appManager = AppManager()
    }
    
    var body: some Scene {
        WindowGroup {
            DiscoveryView()
                .environmentObject(appManager)
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
