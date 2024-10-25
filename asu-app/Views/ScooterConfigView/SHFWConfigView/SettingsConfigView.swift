//
//  SettingsConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/10/2024.
//

import SwiftUI

struct SystemConfigView: View {
    @ObservedObject var global: ScooterManager.SHFWGlobal
    
    var body: some View {
        Section(header: Text("System Settings")) {
            // pwm
            ReleaseSlider(name: "PWM", value: self.$global.pwm, in: 4...24, step: 4)
        }
    }
}
