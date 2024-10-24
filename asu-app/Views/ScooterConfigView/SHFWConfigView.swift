//
//  SHFWConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

private struct ProfileConfigView: View {
    @ObservedObject var profile: ScooterManager.SHFWProfile
    
    var body: some View {
        Section {
            // text field examples
            NumericTF(name: "P3 sports 1", value: $profile.sportsAmps[0], in: 0...100, step: 0.01)
            NumericTF(name: "P3 sports 2", value: $profile.sportsAmps[1], in: 0...100, step: 0.01)
            // slider examples
            ReleaseSlider(name: "P3 sports 3", value: $profile.sportsAmps[2], in: 0...100, step: 0.01)
            ReleaseSlider(name: "P3 sports 4", value: $profile.sportsAmps[3], in: 0...100, step: 0.01)
            
        }
    }
}

private struct SystemConfigView: View {
    @ObservedObject var global: ScooterManager.SHFWGlobal
    
    var body: some View {
        Section {
            // pwm
            ReleaseSlider(name: "PWM", value: $global.pwm, in: 4...24, step: 4)
        }
    }
}

struct SHFWConfigView: View {
    @ObservedObject var shfw: ScooterManager.SHFW

    @State var selectedProfile: Int = 2
    
    var body: some View {
        VStack {
            if let config = self.shfw.config {
                List {
                    ProfileConfigView(profile: config.getProfile(self.selectedProfile))
                    SystemConfigView(global: config.global)
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
