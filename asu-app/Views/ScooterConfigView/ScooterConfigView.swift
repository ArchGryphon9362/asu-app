//
//  ScooterConfigView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 03/02/2024.
//

import Foundation
import SwiftUI
import NavigationBackport

struct ScooterConfigView: View {
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        NBNavigationStack {
            TabView {
                MainConfigView()
                    .tabItem {
                        Label("Main Config", systemImage: "wrench.adjustable")
                    }
                    .padding()
                FlashView()
                    .tabItem {
                        Label("Flash", systemImage: "bolt")
                    }
                    .padding()
                SHFWConfigView()
                    .tabItem {
                        Label("SHFW Config", systemImage: "gear")
                    }
                    .padding()
            }
            .navigationTitle("Scooter Config")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                Button("Close") {
                    self.presentation.wrappedValue.dismiss()
                }
            }
        }
    }
}
