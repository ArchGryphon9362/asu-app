//
//  SettingsView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 31/01/2024.
//

import Foundation
import SwiftUI
import NavigationBackport
import CryptoKit

// stupid ass buttons desynchronizing with Settings due to fast UI refresh 😒
struct SettingsToggle: View {
    var text: String
    @Binding var setting: Bool
    @State private var settingsToggle = false
    
    var body: some View {
        Toggle(isOn: self.$settingsToggle) {
            Text(text)
        }.onChange(of: self.settingsToggle) { newValue in
            self.setting = newValue
        }.onAppear {
            self.settingsToggle = self.setting
        }
    }
}

struct AdvancedSettings: View {
    var body: some View {
        List {
            Section {
                SettingsToggle(text: "Allow flashing mismatched firmware", setting: appSettings.$mismatchedFirmware)
            }
            
            Section {
                SettingsToggle(text: "Increased amperages", setting: appSettings.$increasedAmps)
                SettingsToggle(text: "Enable advanced settings", setting: appSettings.$shfwAdvanced)
            } header: {
                Text("SHFW")
            } footer: {
                Text("In SHFW, advanced settings consist of:\n- PWM\n- ADC resistor calibration\n- BMS emulation")
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentation
    @State var secretValue = ""
    @State var secretMenu = false
    @State var doubleSecretMenu = false
    
    @State var unitsToggle = appSettings.correctSpeedUnits
    
    var body: some View {
        NBNavigationStack {
            List {
                Section {
                    // like seriously apple. fix your crap
                    HStack {
                        Text("App units").onLongPressGesture {
                            self.secretValue = ""
                            self.secretMenu = true
                            self.doubleSecretMenu = false
                        }
                        Spacer()
                        Picker(selection: $unitsToggle, label: Text("")) {
                            Text("imperial").tag(false)
                            Text("metric").tag(true)
                        }.pickerStyle(SegmentedPickerStyle()).fixedSize().onChange(of: unitsToggle) { newValue in
                            appSettings.correctSpeedUnits = newValue
                        }
                    }
                    NavigationLink("Edit dashboard UI", destination: Text("we don't have this yet 😔").navigationTitle("Edit dashboard UI"))
                    NavigationLink("Advanced settings", destination: AdvancedSettings().navigationTitle("Advanced settings"))
                }
                Section {
                    Button("GitHub") {
                        if let url = URL(string: "https://github.com/ArchGryphon9362/asu-app") {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Donate") {
                        if let url = URL(string: "https://ko-fi.com/archgryphon9362") {
                            UIApplication.shared.open(url)
                        }
                    }
                } header: {
                    Text("Contributing")
                } footer: {
                    Text("Developing an app like this (especially a free one) takes lots of time and effort, any contribution is valued. This includes both code contributions through GitHub, and monetary contributions. Thanks for the consideration!")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close") {
                    self.presentation.wrappedValue.dismiss()
                }
            }
            NavigationLink("", destination: VStack {
//                var hasher = SHA256().update(data: self.secretValue.bytes)
                if (!self.doubleSecretMenu) {
                    List {
                        TextField("you look lost...", text: self.$secretValue).onChange(of: self.secretValue) { newValue in
                            var hasher = SHA256()
                            hasher.update(data: newValue.bytes)
                            self.doubleSecretMenu = Data(hasher.finalize()) == secretMenuHash
                        }
                    }
                } else {
                    SecretView()
                }
            }.navigationTitle(!self.doubleSecretMenu ? "You saw nothing..." : "heyy :3").navigationBarTitleDisplayMode(.inline), isActive: self.$secretMenu).hidden()
        }
    }
    
    func secretSubmit() {
        print(self.secretValue)
    }
}
