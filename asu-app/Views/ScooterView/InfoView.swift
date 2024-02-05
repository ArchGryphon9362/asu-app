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
    @State var showConfig: Bool = false
    
    var body: some View {
        VStack {
            List {
                Section {
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
                }
                
                Button("Scooter Config", action: {
                    self.showConfig = true
                })
            }
        }.sheet(isPresented: self.$showConfig, content: {
            ScooterConfigView()
                #if os(macOS)
                .frame(width: 500, height: 300)
                .fixedSize()
                #endif
        })
    }
}
