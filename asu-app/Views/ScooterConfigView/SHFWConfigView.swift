//
//  SHFWConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct SHFWConfigView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    
    var body: some View {
        VStack {
            ListItem(title: "Version", data: scooterManager.shfw.version?.parsed)
            if let p3 = self.scooterManager.shfw.config?.profile3 {
                ForEach(p3.sportsAmps, id: \.self) { value in
                    TextField("P3 Sports Value Number X", value: value, format: .number)
                }
            }
        }
    }
}
