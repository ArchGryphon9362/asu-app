//
//  InfoView.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import SwiftUI

struct InfoView: View {
    @EnvironmentObject var scooterManager: ScooterManager
    @StateObject var scooter: Scooter
    var discoveredScooter: DiscoveredScooter
    
    var body: some View {
        VStack {
            Text("Info tab")
            Text("\(scooter.connectionState.description)")
        }
    }
}
