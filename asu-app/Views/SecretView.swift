//
//  SecretView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 31/01/2024.
//

import Foundation
import SwiftUI

struct SecretView: View {
    @State var allowForceNbCrypto: Bool = appSettings.allowForceNbCrypto
    
    var body: some View {
        List {
            Section {
                Text("welcome to my secret lair 😈")
            }
            Section {
                SettingsToggle(text: "Allow forcing NinebotCrypto", setting: appSettings.$allowForceNbCrypto)
                SettingsToggle(text: "Fox mode 🦊", setting: appSettings.$foxMode)
            }
        }
    }
}
