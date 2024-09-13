//
//  InfoView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct InfoView: View {
    @EnvironmentObject var appManager: AppManager
    @State var showConfig: Bool = false
    
    var body: some View {
        VStack {
            List {
                Section {
                    ListItem(title: "Model", data: self.appManager.scooter.model?.name)
                    ListItem(title: "BLE", data: self.appManager.scooter.ble)
                    ListItem(title: "DRV", data: self.appManager.scooter.esc)
                    ListItem(title: "BMS", data: self.appManager.scooter.bms)
                    ListItem(title: "Serial Number", data: self.appManager.scooter.serial)
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
