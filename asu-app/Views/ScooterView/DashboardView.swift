//
//  DashboardView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 03/02/2024.
//

import Foundation
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    
    var body: some View {
        List {
            let fox = appSettings.foxMode ? "🦊" : ""
            Text("vroom 😎" + fox)
            Button("Reboot") {
                // TODO: reimplement
                print("lol no more, you fucking wish. wait for ScooterManager.swift v2 lmfaooo")
            }
        }
    }
}
