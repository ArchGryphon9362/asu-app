//
//  ContentView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import CoreBluetooth

struct DiscoveryView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    @State var forceNbCrypto: [UUID: Bool] = [:]
    
    var body: some View {
        VStack {
            NavigationStack {
//                Text("Pick your scooter").font(.system(size: 16.0)).bold().padding()
                List(Array(scooterManager.discoveredScooters.values)) { scooter in
                    HStack {
                        VStack(alignment: .leading) {
                            NavigationLink(scooter.name, value: scooter)
                                .bold()
                                .font(.title2)
                            Text(scooter.model.name)
                            if (scooter.mac != "") {
                                Text(scooter.mac)
                            }
                            Text("RSSI: \(scooter.rssi)dB")
                        }
                        Spacer()
                        Image(scooter.model.image)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)
                    }.listRowSeparator(.visible).background().contextMenu(menuItems: {
                        var forceValue = forceNbCrypto[scooter.peripheral.identifier] ?? false
                        
                        Button {
                            forceValue.toggle()
                            forceNbCrypto[scooter.peripheral.identifier] = forceValue
                        } label: {
                            Label("Force NinebotCrypto", systemImage: forceValue ? "checkmark.circle.fill" : "x.circle")
                        }
                    })
                }
                .scrollContentBackground(.hidden).listStyle(.inset)
                .navigationTitle("Pick your scooter")
                .navigationDestination(for: DiscoveredScooter.self) { scooter in
                    ScooterView(
                        scooter: scooterManager.scooter,
                        discoveredScooter: scooter,
                        forceNbCrypto: forceNbCrypto[scooter.peripheral.identifier] ?? false
                    ).navigationTitle(scooter.name)
                }
            }
        }
    }
}
