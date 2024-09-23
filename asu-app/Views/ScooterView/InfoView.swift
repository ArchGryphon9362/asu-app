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
                    ListItem(title: "Model", data: self.scooterManager.model?.name)
                    ListItem(title: "BLE", data: self.scooterManager.coreInfo.ble?.parsed)
                    ListItem(title: "DRV", data: self.scooterManager.coreInfo.esc?.parsed)
                    ListItem(title: "BMS", data: self.scooterManager.coreInfo.bms?.parsed)
                    ListItem(title: "Serial Number", data: self.scooterManager.coreInfo.serial)
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
