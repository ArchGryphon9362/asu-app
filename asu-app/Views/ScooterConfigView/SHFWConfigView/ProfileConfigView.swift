//
//  ProfileConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/10/2024.
//

import SwiftUI

private struct ProfileOptionsView: View {
    @Binding var selectedProfile: Int
    
    var body: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Editing Profile")
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

private struct ThrottleSelectionView: View {
    @Binding var throttleCurve: Int
    
    var body: some View {
        Picker("", selection: self.$throttleCurve) {
            Text("Eco").tag(0)
            Text("Drive").tag(1)
            Text("Sports").tag(2)
        }.pickerStyle(.segmented)
    }
}

private struct SpeedLimitView: View {
    @Binding var speedLimit: Int
    @Binding var speedBased: Bool
    
    var body: some View {
        let minSpeedLimit: Float = self.speedBased ? 1 : 0
        let unitConversion: Float = appSettings.correctSpeedUnits ? 1.0 : 1.6
        let unit: String = appSettings.correctSpeedUnits ? "km/h" : "mi/h"
        let displayPrecision: Int = appSettings.correctSpeedUnits ? 0 : 1
        ReleaseSlider(
            name: "Speed Limit",
            value: self.$speedLimit,
            in: (minSpeedLimit / unitConversion)...(65 / unitConversion),
            unit: unit,
            step: 1 / unitConversion,
            scaleFactor: unitConversion,
            displayPrecision: displayPrecision,
            mapping: [
                0: "Off"
            ]
        )
    }
}

private struct ThrottleModeView: View {
    @Binding var speedLimit: Int
    @Binding var speedBased: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Throttle Mode")
                .font(.footnote)
                .foregroundColor(.secondary)
            Picker("", selection: self.$speedBased) {
                Text("Speed Based")
                    .tag(true)
                    .disabled(self.speedLimit == 0)
                Text("Power Based (DPC)")
                    .tag(false)
            }
            .pickerStyle(.segmented)
            .disabled(self.speedLimit == 0 && !self.speedBased)
        }
    }
}

private struct CurveView: View {
    @Binding var curve: [Float]
    
    var body: some View {
        ReleaseSlider(name: "Point 1", value: self.$curve[0], in: 0...100, unit: "A", step: 0.01)
        ReleaseSlider(name: "Point 2", value: self.$curve[1], in: 0...100, unit: "A", step: 0.01)
        ReleaseSlider(name: "Point 3", value: self.$curve[2], in: 0...100, unit: "A", step: 0.01)
        ReleaseSlider(name: "Point 4", value: self.$curve[3], in: 0...100, unit: "A", step: 0.01)
    }
}

private struct ProfileDataView: View {
    @ObservedObject var profile: ScooterManager.SHFWProfile
    
    @State private var throttleCurve = 0
    
    var body: some View {
        // TODO: DisclosureGroup? would need to make indentation not ugly...
        // TODO: using listRowSeparator's would be nice, but iOS 15+
        Section(header: Text("Throttle")) {
            ThrottleSelectionView(throttleCurve: self.$throttleCurve)
            SpeedLimitView(
                speedLimit: self.getSmoothness(self.throttleCurve).speedLimit,
                speedBased: self.getSpeedBased(self.throttleCurve)
            )
            ThrottleModeView(
                speedLimit: self.getSmoothness(self.throttleCurve).speedLimit,
                speedBased: self.getSpeedBased(self.throttleCurve)
            )
            if !self.getSpeedBased(self.throttleCurve).wrappedValue {
                CurveView(curve: self.getCurve(self.throttleCurve))
            } else {
                ReleaseSlider(name: "Power Limit", value: self.getCurve(self.throttleCurve)[3], in: 0...100, unit: "A", step: 0.01)
                ReleaseSlider(name: "Current Smoothness", value: self.getSmoothness(self.throttleCurve).smoothness, in: 0...2500, unit: "mA", step: 100)
            }
        }
        
        Section(header: Text("Brake")) {
            CurveView(curve: self.$profile.brakeAmps)
        }
    }
    
    private func getCurve(_ curveNumber: Int) -> Binding<[Float]> {
        [
            self.$profile.ecoAmps,
            self.$profile.driveAmps,
            self.$profile.sportsAmps
        ][curveNumber]
    }
    
    private func getSmoothness(_ curveNumber: Int) -> Binding<SHFWMessage.SpeedBasedConfig> {
        [
            self.$profile.ecoSmoothness,
            self.$profile.driveSmoothness,
            self.$profile.sportsSmoothness
        ][curveNumber]
    }
    
    private func getSpeedBased(_ curveNumber: Int) -> Binding<Bool> {
        [
            self.$profile.booleans.ecoSpeedBased,
            self.$profile.booleans.driveSpeedBased,
            self.$profile.booleans.sportsSpeedBased
        ][curveNumber]
    }
}

struct ProfileConfigView: View {
    @ObservedObject var config: ScooterManager.SHFWConfig
    
    @State private var selectedProfile: Int = 0

    var body: some View {
        List {
            ProfileOptionsView(selectedProfile: self.$selectedProfile)
            ProfileDataView(profile: self.config.getProfile(self.selectedProfile))
        }
    }
}
