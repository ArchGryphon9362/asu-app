//
//  ScooterConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 03/02/2024.
//

import Foundation
import SwiftUI
import NavigationBackport
import Combine

struct ScooterConfigView: View {
    @Environment(\.presentationMode) var presentation
    
    @EnvironmentObject var scooterManager: ScooterManager
    
    @State var selectedTab = 0
    @State var prevSelectedTab = 0
    
    var navigationTitle: String {
        switch self.selectedTab {
        case 0: "Main Config"
        case 1: "Flash"
        case 2: "SHFW Config"
        default: "Scooter Config"
        }
    }

    @State var shfwMissingAlert = false
    
    @State private var shfwCancellable: AnyCancellable? = nil
    
    var body: some View {
        NBNavigationStack {
            TabView(selection: self.$selectedTab) {
                MainConfigView()
                    .tabItem {
                        Label("Main Config", systemImage: "wrench.adjustable")
                    }
                    .tag(0)
                FlashView()
                    .tabItem {
                        Label("Flash", systemImage: "bolt")
                    }
                    .tag(1)
                SHFWConfigView(shfw: self.scooterManager.shfw)
                    .tabItem {
                        Label("SHFW Config", systemImage: "gear")
                    }
                    .tag(2)
            }
            .navigationTitle(self.navigationTitle)
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.automatic)
            #endif
            .toolbar {
                Button("Close") {
                    self.presentation.wrappedValue.dismiss()
                }
            }
            .onAppear {
                self.shfwCancellable = self.scooterManager.shfw.objectWillChange.sink { _ in
                    self.checkShfwPopup()
                }
            }
            .onChange(of: self.selectedTab) { newTab in
                guard !checkShfwPopup() else { return }
                self.prevSelectedTab = newTab
            }
            .alert(isPresented: self.$shfwMissingAlert, content: {
                guard self.scooterManager.shfw.installed != nil else {
                    return Alert(
                        title: Text("SHFW Loading..."),
                        message: Text("Still checking for presence of SHFW..."),
                        dismissButton: .cancel(Text("OK")) {
                            self.selectedTab = self.prevSelectedTab
                        }
                    )
                }
                
                guard self.scooterManager.shfw.updateStatus != .required else {
                    return Alert(
                        title: Text("SHFW Update Required!"),
                        message: Text("This app doesn't support your version of SHFW (\(self.scooterManager.shfw.version?.parsed ?? "unknown")). If you want to use this app to configure your SHFW install you will have to flash a newer version!"),
                        primaryButton: .cancel(Text("OK")) {
                            self.selectedTab = self.prevSelectedTab
                        },
                        secondaryButton: .default(Text("Update")) {
                            self.selectedTab = 1
                            // TODO: pop open shfw flasher
                        }
                    )
                }

                switch self.scooterManager.shfw.compatible {
                case true:
                    return Alert(
                        title: Text("SHFW Missing!"),
                        message: Text("Your scooter doesn't currently have SHFW installed!"),
                        primaryButton: .cancel(Text("OK")) {
                            self.selectedTab = self.prevSelectedTab
                        },
                        secondaryButton: .default(Text("Install")) {
                            self.selectedTab = 1
                            // TODO: pop open shfw flasher
                        }
                    )
                case false:
                    return Alert(
                        title: Text("SHFW Missing!"),
                        message: Text("Your scooter doesn't support SHFW!"),
                        dismissButton: .default(Text("OK")) {
                            self.selectedTab = self.prevSelectedTab
                        }
                    )
                // TODO: change this alert if shfw (un)discovered (or will swiftui be a nice one and do this for me??)
                default:
                    return Alert(
                        title: Text("SHFW Missing!"),
                        message: Text("Compatability unknown, you may still attempt an install"),
                        primaryButton: .cancel(Text("OK")) {
                            self.selectedTab = self.prevSelectedTab
                        },
                        secondaryButton: .default(Text("Try install")) {
                            self.selectedTab = 1
                            // TODO: pop open shfw flasher
                        }
                    )
                }
            })
        }
    }
    
    @discardableResult
    func checkShfwPopup() -> Bool {
        guard
            self.scooterManager.shfw.installed != true ||
            self.scooterManager.shfw.updateStatus == .required else {
            self.shfwMissingAlert = false
            return false
        }
        
        guard self.selectedTab == 2 else {
            return false
        }
        
        self.shfwMissingAlert = true
        return true
    }
}
