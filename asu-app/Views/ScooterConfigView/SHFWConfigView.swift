//
//  SHFWConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct SHFWConfigView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    
    @State var s1: Float = 0
    @State var s2: Float = 0

    var body: some View {
        VStack {
            if var config = self.scooterManager.shfw.config {
                List {
                    let _config = Binding(get: { config }, set: { newValue in config = newValue })
                    
                    // text field examples
                    NumericTF(name: "P3 sports 1", value: _config.profile3.sportsAmps[0], in: 0...100, step: 0.01)
                    NumericTF(name: "P3 sports 2", value: _config.profile3.sportsAmps[1], in: 0...100, step: 0.01)
                    // slider examples
                    ReleaseSlider(name: "P3 sports 3", value: _config.profile3.sportsAmps[2], in: 0...100, step: 0.01)
                    ReleaseSlider(name: "P3 sports 4", value: _config.profile3.sportsAmps[3], in: 0...100, step: 0.01)
                    
                    // pwm
                    ReleaseSlider(name: "PWM", value: _config.global.pwm, in: 4...24, step: 4)
                }
            } else if self.scooterManager.shfw.installed == true {
                HStack {
                    ProgressView()
                    Text("Loading SHFW config")
                }
            }
        }
    }
}
