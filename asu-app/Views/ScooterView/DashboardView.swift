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
            Text("vroom 😎🦊")
            Button("Reboot") {
                let msg = self.scooterManager.messageManager.ninebotWrite(.powerOff(false), ack: false)
                var send = false
                self.scooterManager.write(msg) {
                    send.toggle()
                    return send
                }
            }
        }
    }
}
