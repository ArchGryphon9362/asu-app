//
//  SHFWConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI
import NavigationBackport

struct SHFWConfigView: View {
    @ObservedObject var shfw: ScooterManager.SHFW

    var body: some View {
        VStack {
            if let config = self.shfw.config {
                NBNavigationStack {
                    List {
                        NavigationLink("Profile Settings") {
                            ProfileConfigView(config: config)
                                .navigationTitle("Profile Settings")
                                .navigationBarTitleDisplayMode(.large)
                        }
                        NavigationLink("System Settings") {
                            SystemConfigView(global: config.global)
                                .navigationTitle("System Settings")
                                .navigationBarTitleDisplayMode(.large)
                        }
                    }
                }
            } else if self.shfw.installed == true {
                HStack {
                    ProgressView()
                    Text("Loading SHFW config")
                }
            } else {
                Text("Dear hyuman, we do not have the kinds of resources needed to switch you back to the tab you came from, and the popup doing that for us appears to have not shown. Kindly go back to the previous tab as this one is empty :(").padding()
            }
        }
    }
}
