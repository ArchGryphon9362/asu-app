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
    @ObservedObject var shfw: ScooterManager.SHFW
    
    var body: some View {
        Section(header: Text("General Info")) {
            ListItem(title: "Model", data: model?.name)
            ListItem(title: "BLE", data: coreInfo.ble?.parsed)
            if let shfwVersion = self.shfw.version {
                // TODO: fix self.shfw.config assignment causing rerender (and thus collapse)
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
    
    var body: some View {
        VStack {
            List {
                BaseInfoView(
                    model: self.scooterManager.model,
                    coreInfo: self.scooterManager.coreInfo,
                    shfw: self.scooterManager.shfw
                )
                
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
