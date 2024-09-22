//
//  ScooterView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct ScooterView: View {
    @Environment(\.presentationMode) var presentation
    
    @EnvironmentObject var appManager: AppManager
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
            TripsView()
                .tabItem {
                    Label("Trips", systemImage: "list.bullet.below.rectangle")
                }
            InfoView()
                .tabItem {
                    Label("Info", systemImage: "info.circle")
                }
        }
        .onAppear {
            self.appManager.scooter.connectTo(discoveredScooter: discoveredScooter, forceNbCrypto: self.forceNbCrypto)
        }
        .onDisappear {
            self.appManager.scooter.disconnectFromScooter()
            self.connectingMessage = "Please wait..."
        }
        .onChange(of: self.appManager.scooter.connectionState) { state in
            if self.appManager.scooter.authenticating {
                switch(self.appManager.scooter.model?.scooterProtocol(forceNbCrypto: self.forceNbCrypto)) {
                case .xiaomi(true):
                    self.connectingMessage = "Authenticating with scooter...\n\nPlease toggle the headlight by pressing the power button."
                default:
                    // totally not stolen line
                    self.connectingMessage = "Authenticating with scooter...\n\nIf this does nothing after a few seconds, please toggle the headlight by pressing the power button."
                }
            } else {
                self.connectingMessage = "Please wait..."
            }
            
            // TODO: make sure to do some stuff when blocking ui state updates
            
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
                    self.appManager.scooter.disconnectFromScooter()
                    self.connectingMessage = "Please wait..."
                    self.presentation.wrappedValue.dismiss()
                }
            )
        }
    }
}
