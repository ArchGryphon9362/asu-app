//
//  DiscoveryView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import CoreBluetooth
import NavigationBackport

struct DiscoveryView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    @State var forceNbCrypto: [UUID: Bool] = [:]
    #if !os(macOS)
    @State var isSettingsOpen: Bool = false
    let haptics = UINotificationFeedbackGenerator()
    #endif
    
    var body: some View {
        NBNavigationStack {
            List(Array(scooterManager.discoveredScooters.values), id: \.peripheral.identifier) { scooter in
                HStack {
                    VStack(alignment: .leading) {
                        Text(scooter.name).bold().font(.title2).background(
                            NavigationLink("", destination: ScooterView(
                                discoveredScooter: scooter,
                                forceNbCrypto: forceNbCrypto[scooter.peripheral.identifier] ?? false
                            )
                                .navigationTitle(scooter.name)
                                #if !os(macOS)
                                .toolbar {
                                    Button("Settings") {
                                        self.isSettingsOpen = true
                                    }
                                }
                                .sheet(isPresented: $isSettingsOpen, content: {
                                    SettingsView()
                                })
                                #endif
                        ).opacity(0))
                        Text(scooter.model.name)
                        if (scooter.mac != "") {
                            Text(scooter.mac)
                        }
                        Text("RSSI: \(scooter.rssi)dB")
                    }
                    Spacer()
                    VStack {
                        Image(scooter.model.image)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                        if forceNbCrypto[scooter.peripheral.identifier] ?? false {
                            Text("Forcing NBCrypto").foregroundColor(.red).font(.footnote)
                        }
                    }.frame(height: 80)
                }.contextMenu(menuItems: {
                    if (appSettings.allowForceNbCrypto) {
                        var forceValue = forceNbCrypto[scooter.peripheral.identifier] ?? false
                        
                        Button {
                            forceValue.toggle()
                            forceNbCrypto[scooter.peripheral.identifier] = forceValue
                            #if !os(macOS)
                            haptics.notificationOccurred(forceValue ? .success : .warning)
                            #endif
                        } label: {
                            Label("Force NinebotCrypto", systemImage: forceValue ? "checkmark.circle.fill" : "x.circle")
                        }
                    }
                })
            }
            .listStyle(.inset)
            .navigationTitle("Pick your scooter" + (appSettings.foxMode ? " 🦊" : ""))
            .background(Text(appSettings.foxMode.description).hidden()) // TODO: this doesn't fix fox mode not changing title
            #if !os(macOS)
            .toolbar {
                Button("Settings") {
                    self.isSettingsOpen = true
                }
            }
            .sheet(isPresented: $isSettingsOpen, content: {
                SettingsView()
            })
            #endif
        }
    }
}
