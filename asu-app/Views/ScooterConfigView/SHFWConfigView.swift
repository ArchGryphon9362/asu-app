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
        ListItem(title: "Version", data: scooterManager.shfw.version?.parsed)
    }
}

#Preview {
    SHFWConfigView()
}
