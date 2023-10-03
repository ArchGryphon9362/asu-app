//
//  ContentView.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import CoreBluetooth

struct DiscoveryView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    
    var body: some View {
        VStack {
            NavigationStack {
//                Text("Pick your scooter").font(.system(size: 16.0)).bold().padding()
                List(Array(scooterManager.discoveredScooters.values)) { scooter in
                    HStack {
                        VStack(alignment: .leading) {
                            NavigationLink(scooter.name, value: scooter).bold()
                            Text(scooter.model.name)
                            Text("RSSI: \(scooter.rssi)dB")
                        }
                        Spacer()
                        Image(scooter.model.image).resizable().aspectRatio(contentMode: .fit).frame(height: 80)
                    }.listRowSeparator(.visible)
                }
                .scrollContentBackground(.hidden).listStyle(.inset)
                .navigationTitle("Pick your scooter")
                .navigationDestination(for: DiscoveredScooter.self) { scooter in
                    ScooterView(scooter: scooterManager.scooter, discoveredScooter: scooter)
                        .navigationTitle(scooter.name)
                }
            }
        }
    }
}

#Preview {
    DiscoveryView()
        .environmentObject(ScooterManager())
}
