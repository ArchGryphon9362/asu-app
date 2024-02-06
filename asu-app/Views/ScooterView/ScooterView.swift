//
//  ScooterView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct ScooterView: View {
    @Environment(\.presentationMode) var presentation
    
    @EnvironmentObject var scooterManager: ScooterManager
    var discoveredScooter: DiscoveredScooter
    var forceNbCrypto: Bool
    
    @State private var showConnectingPopup = false
    @State private var connectingMessage = "Please wait..."
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "scooter")
                }
            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
        }
        .onAppear {
            self.scooterManager.connectTo(discoveredScooter: discoveredScooter, forceNbCrypto: self.forceNbCrypto)
        }
        .onDisappear {
            self.scooterManager.disconnectFromScooter(updateUi: true)
            self.connectingMessage = "Please wait..."
        }
        .onChange(of: self.scooterManager.scooter.connectionState) { state in
            if self.scooterManager.scooter.authenticating {
                switch(self.scooterManager.scooter.model?.scooterProtocol(forceNbCrypto: self.forceNbCrypto)) {
                case .xiaomi(true):
                    self.connectingMessage = "Authenticating with scooter...\n\nPlease toggle the headlight by pressing the power button."
                default:
                    // totally not stolen line
                    self.connectingMessage = "Authenticating with scooter...\n\nIf this does nothing after a few seconds, please toggle the headlight by pressing the power button."
                }
            } else {
                self.connectingMessage = "Please wait..."
            }
            
            guard !self.scooterManager.scooterBluetooth.blockDisconnectUpdates else {
                return
            }
            
            if state == .disconnected {
                self.presentation.wrappedValue.dismiss()
            }
            
            self.showConnectingPopup = state != .connected && state != .disconnected
        }
        .alert(isPresented: self.$showConnectingPopup) {
            let message = Text(connectingMessage)
            return Alert(
                title: Text("Connecting..."), // TODO: allowing heading to change too
                message: message,
                dismissButton: .destructive(Text("Disconnect")) {
                    self.scooterManager.disconnectFromScooter(updateUi: true)
                    self.connectingMessage = "Please wait..."
                    self.presentation.wrappedValue.dismiss()
                }
            )
        }
    }
}
