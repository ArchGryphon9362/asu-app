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

struct FooterText: View {
    var text: String
    
    var body: some View {
        Text(text).font(.callout).bold().foregroundColor(.gray)
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
                FooterText(text: "In SHFW, advanced settings consist of:\n  - PWM\n  - ADC resistor calibration\n  - BMS emulation")
            } header: {
                Text("SHFW")
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
                    NavigationLink("Edit dashboard UI", destination: List { Text("we don't have this yet 😔") }.navigationTitle("Edit dashboard UI"))
                    NavigationLink("Advanced settings", destination: AdvancedSettings().navigationTitle("Advanced settings"))
                }
                Section {
                    Button("GitHub") {
                        openUrl(url: "https://github.com/ArchGryphon9362/asu-app")
                    }
                    Button("Donate") {
                        openUrl(url: "https://ko-fi.com/archgryphon9362")
                    }
                    FooterText(text: "Developing an app like this (especially a free one) takes lots of time and effort, any contribution is valued. This includes both code contributions through GitHub, and monetary contributions. Thanks for the consideration!")
                } header: {
                    Text("Contributing")
                }
            }
            .navigationTitle("Settings")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Close") {
                    self.presentation.wrappedValue.dismiss()
                }
            }
            #endif
            .background(
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
                }
                    .navigationTitle(!self.doubleSecretMenu ? "You saw nothing..." : "heyy :3")
                    #if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                , isActive: self.$secretMenu
                ).hidden()
            )
        }
    }
    
    func secretSubmit() {
        print(self.secretValue)
    }
}

#if os(macOS)
class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
