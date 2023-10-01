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
    
    @State private var showConnectingPopup = false
    @State private var connectingMessage = "Please wait..."
    
    var body: some View {
        TabView {
            InfoView(scooter: self.scooter, discoveredScooter: self.discoveredScooter)
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
            self.scooterManager.connectToScooter(scooter: discoveredScooter)
        }
        .onDisappear {
            self.scooterManager.disconnectFromScooter(scooter: discoveredScooter)
        }
        .onChange(of: scooter.connectionState) { _, state in
            if state == .disconnected {
                self.presentation.wrappedValue.dismiss()
            }
            
            if state == .pairing {
                self.connectingMessage = "Toggle the headlight to complete pairing"
            } else {
                self.connectingMessage = "Please wait..."
            }
            
            self.showConnectingPopup = state != .connected
        }
        .alert(isPresented: self.$showConnectingPopup) {
            var message = Text(connectingMessage)
            return Alert(
                title: Text("Connecting..."),
                message: message,
                dismissButton: .destructive(Text("Disconnect")) {
                    self.scooterManager.disconnectFromScooter(scooter: discoveredScooter)
                }
            )
        }
    }
}
