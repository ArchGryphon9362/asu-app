//
//  InfoView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct InfoView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    @StateObject var scooter: Scooter
    var discoveredScooter: DiscoveredScooter
    
    var body: some View {
        VStack {
            HStack {
                Text("Model")
                Spacer()
                Text("\(scooter.model?.name ?? "N/A")")
            }
            HStack {
                Text("BLE")
                Spacer()
                Text("\(scooter.ble ?? "N/A")")
            }
            HStack {
                Text("DRV")
                Spacer()
                Text("\(scooter.esc ?? "N/A")")
            }
            HStack {
                Text("BMS")
                Spacer()
                Text("\(scooter.bms ?? "N/A")")
            }
            HStack {
                Text("Serial number")
                Spacer()
                Text("\(scooter.serial ?? "N/A")")
            }
            Spacer()
        }
    }
}
