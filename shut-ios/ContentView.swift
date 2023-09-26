//
//  ContentView.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var scooter: Scooter
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text(scooter.esc ?? "N/A")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
