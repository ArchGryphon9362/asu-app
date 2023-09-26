//
//  ContentView.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text(scooterManager.scooter.esc ?? "N/A")
            ForEach(Array(scooterManager.discoveredScooters.values)) { scooter in
                Button("\(scooter.name): \(scooter.rssi)") {
                    scooterManager.connectToScooter(scooter: scooter)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(ScooterManager())
}
