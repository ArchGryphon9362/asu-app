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
    @State var escVersion: String? = nil
    
    var body: some View {
        VStack {
            List {
                Section {
                    ListItem(title: "Model", data: self.scooterManager.model?.name)
                    ListItem(title: "BLE", data: self.scooterManager.coreInfo.ble?.parsed)
                    if let shfwVersion = self.scooterManager.shfw.version {
                        SHFWVersionItem(version: shfwVersion)
                    } else {
                        ListItem(title: "DRV", data: self.scooterManager.coreInfo.esc?.parsed)
                    }
                    ListItem(title: "BMS", data: self.scooterManager.coreInfo.bms?.parsed)
                    ListItem(title: "Serial Number", data: self.scooterManager.coreInfo.serial)
                }
                
                Button("Scooter Config", action: {
                    self.showConfig = true
                })
            }
        }.onAppear {
            self.updateEscVersion()
        }.onChange(of: self.scooterManager.coreInfo.esc) { _ in
            self.updateEscVersion()
        }.onChange(of: self.scooterManager.shfw.version) { _ in
            self.updateEscVersion()
        }.sheet(isPresented: self.$showConfig, content: {
            ScooterConfigView()
                #if os(macOS)
                .frame(width: 500, height: 300)
                .fixedSize()
                #endif
        })
    }
    
    func updateEscVersion() {
        guard let shfwVersion = self.scooterManager.shfw.version else {
            self.escVersion = self.scooterManager.coreInfo.esc?.parsed
            return
        }
        
        var newVersion = shfwVersion.parsed
        
        if let extraDetails = shfwVersion.extraDetails {
            if let buildDetails = extraDetails.buildDetails {
                newVersion += " | \(buildDetails)"
            }
            newVersion += " | \(extraDetails.buildType.string.capitalized)"
        }
        
        self.escVersion = newVersion
    }
}
