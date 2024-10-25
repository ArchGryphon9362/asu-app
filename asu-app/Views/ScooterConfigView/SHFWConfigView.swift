//
//  SHFWConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI
import NavigationBackport

private struct ProfileOptionsView: View {
    @Binding var selectedProfile: Int
    
    var body: some View {
        Section(header: Text("Profile")) {
            VStack(alignment: .leading) {
                Text("Selected Profile")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Picker("", selection: self.$selectedProfile) {
                    Text("1").tag(0)
                    Text("2").tag(1)
                    Text("3").tag(2)
                }.pickerStyle(.segmented)
            }
        }
    }
}

private struct ProfileConfigView: View {
    @ObservedObject var profile: ScooterManager.SHFWProfile
    
    var body: some View {
        Section(header: Text("Throttle")) {
            ReleaseSlider(name: "Sports 1", value: self.$profile.sportsAmps[0], in: 0...100, step: 0.01)
            ReleaseSlider(name: "Sports 2", value: self.$profile.sportsAmps[1], in: 0...100, step: 0.01)
            ReleaseSlider(name: "Sports 3", value: self.$profile.sportsAmps[2], in: 0...100, step: 0.01)
            ReleaseSlider(name: "Sports 4", value: self.$profile.sportsAmps[3], in: 0...100, step: 0.01)
        }
    }
}

private struct SystemConfigView: View {
    @ObservedObject var global: ScooterManager.SHFWGlobal
    
    var body: some View {
        Section(header: Text("System Settings")) {
            // pwm
            ReleaseSlider(name: "PWM", value: self.$global.pwm, in: 4...24, step: 4)
        }
    }
}

struct SHFWConfigView: View {
    @ObservedObject var shfw: ScooterManager.SHFW

    @State var selectedProfile: Int = 0
    
    var body: some View {
        VStack {
            if let config = self.shfw.config {
                NBNavigationStack {
                    List {
                        NavigationLink("Profile Settings") {
                            List {
                                ProfileOptionsView(selectedProfile: self.$selectedProfile)
                                ProfileConfigView(profile: config.getProfile(self.selectedProfile))
                            }
                            .navigationTitle("Profile Settings")
                            .navigationBarTitleDisplayMode(.large)
                        }
                        NavigationLink("System Settings") {
                            List {
                                SystemConfigView(global: config.global)
                            }
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
