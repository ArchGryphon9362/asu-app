//
//  InfoView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct InfoView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    @State var showConfig: Bool = false
    
    var body: some View {
        VStack {
            List {
                Section {
                    HStack {
                        Text("Model")
                        Spacer()
                        Text("\(self.scooterManager.scooter.model?.name ?? "N/A")")
                    }
                    HStack {
                        Text("BLE")
                        Spacer()
                        Text("\(self.scooterManager.scooter.ble ?? "N/A")")
                    }
                    HStack {
                        Text("DRV")
                        Spacer()
                        Text("\(self.scooterManager.scooter.esc ?? "N/A")")
                    }
                    HStack {
                        Text("BMS")
                        Spacer()
                        Text("\(self.scooterManager.scooter.bms ?? "N/A")")
                    }
                    HStack {
                        Text("Serial number")
                        Spacer()
                        Text("\(self.scooterManager.scooter.serial ?? "N/A")")
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
