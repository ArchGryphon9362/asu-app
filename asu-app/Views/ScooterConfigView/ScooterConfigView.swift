//
//  ScooterConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 03/02/2024.
//

import Foundation
import SwiftUI
import NavigationBackport

struct ScooterConfigView: View {
    @Environment(\.presentationMode) var presentation
    
    @EnvironmentObject var appManager: AppManager
    
    @State var selectedTab = 0
    @State var prevSelectedTab = 0
    
    @State var shfwMissingAlert = false
    
    var body: some View {
        NBNavigationStack {
            TabView(selection: self.$selectedTab) {
                MainConfigView()
                    .tabItem {
                        Label("Main Config", systemImage: "wrench.adjustable")
                    }
                    .tag(0)
                    .padding()
                FlashView()
                    .tabItem {
                        Label("Flash", systemImage: "bolt")
                    }
                    .tag(1)
                    .padding()
                SHFWConfigView()
                    .tabItem {
                        Label("SHFW Config", systemImage: "gear")
                    }
                    .tag(2)
                    .padding()
            }
            .navigationTitle("Scooter Config")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                Button("Close") {
                    self.presentation.wrappedValue.dismiss()
                }
            }
            .onChange(of: self.selectedTab) { newTab in
                if newTab == 2 {
                    if self.appManager.scooter.shfw.installed != true {
                        self.shfwMissingAlert = true
                        return
                    }
                }
                
                self.prevSelectedTab = newTab
            }
            .onChange(of: self.appManager.scooter.shfw.installed) { installed in
                guard installed == true else { return }
                self.shfwMissingAlert = false
            }
            .alert(isPresented: self.$shfwMissingAlert, content: {
                guard self.appManager.scooter.shfw.installed != nil else {
                    return Alert(
                        title: Text("SHFW Loading..."),
                        message: Text("Still checking for presence of SHFW..."),
                        dismissButton: .cancel(Text("OK")) {
                            self.selectedTab = self.prevSelectedTab
                        }
                    )
                }
                
                switch self.appManager.scooter.shfw.compatible {
                case true:
                    return Alert(
                        title: Text("SHFW Missing!"),
                        message: Text("Your scooter doesn't currently have SHFW installed!"),
                        primaryButton: .cancel(Text("OK")),
                        secondaryButton: .default(Text("Install")) {
                            self.selectedTab = 1
                            // TODO: pop open shfw flasher
                        }
                    )
                case false: 
                    return Alert(
                        title: Text("SHFW Missing!"),
                        message: Text("Your scooter doesn't support SHFW!"),
                        dismissButton: .default(Text("OK"))
                    )
                // TODO: change this alert if shfw (un)discovered (or will swiftui be a nice one and do this for me??)
                default:
                    return Alert(
                        title: Text("SHFW Missing!"),
                        message: Text("Compatability unknown, you may still attempt an install"),
                        primaryButton: .cancel(Text("OK")),
                        secondaryButton: .default(Text("Install")) {
                            self.selectedTab = 1
                            // TODO: pop open shfw flasher
                        }
                    )
                }
            })
        }
    }
}
