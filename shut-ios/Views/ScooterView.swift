//
//  ScooterView.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct ScooterView: View {
    @Environment(\.presentationMode) var presentation
    
    @EnvironmentObject var scooterManager: ScooterManager
    @StateObject var scooter: Scooter
    var discoveredScooter: DiscoveredScooter
    
    var body: some View {
        TabView {
            InfoView(scooter: scooter, discoveredScooter: discoveredScooter)
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
            ToolsView()
                .tabItem {
                    Label("Tools", systemImage: "wrench.adjustable")
                }
            FlashView()
                .tabItem {
                    Label("Flash", systemImage: "bolt")
                }
            ConfigView()
                .tabItem {
                    Label("Config", systemImage: "gear")
                }
        }
        .onAppear {
            scooterManager.connectToScooter(scooter: discoveredScooter)
        }
        .onDisappear {
            scooterManager.disconncetFromScooter(scooter: discoveredScooter)
        }
        .onChange(of: scooter.connectionState) { _, state in
            if state == .disconnected {
                self.presentation.wrappedValue.dismiss()
            }
        }
    }
}
