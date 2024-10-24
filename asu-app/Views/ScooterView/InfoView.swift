//
//  InfoView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

private struct BaseInfoView: View {
    var model: ScooterModel?
    @ObservedObject var coreInfo: ScooterManager.CoreInfo
    @ObservedObject var infoDump: ScooterManager.InfoDump
    @ObservedObject var shfw: ScooterManager.SHFW
    
    var body: some View {
        Section {
            ListItem(title: "Model", data: model?.name)
            ListItem(title: "BLE", data: coreInfo.ble?.parsed)
            if let shfwVersion = shfw.version {
                SHFWVersionItem(version: shfwVersion)
            } else {
                ListItem(title: "DRV", data: coreInfo.esc?.parsed)
            }
            ListItem(title: "BMS", data: coreInfo.bms?.parsed)
            ListItem(title: "Serial Number", data: coreInfo.serial)
        }
    }
}

struct InfoView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    @State var showConfig: Bool = false
    @State var escVersion: String? = nil
    
    var body: some View {
        VStack {
            List {
                BaseInfoView(
                    model: self.scooterManager.model,
                    coreInfo: self.scooterManager.coreInfo,
                    infoDump: self.scooterManager.infoDump,
                    shfw: self.scooterManager.shfw
                )
                
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
