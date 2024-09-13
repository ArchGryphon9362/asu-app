//
//  DashboardView.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 03/02/2024.
//

import Foundation
import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appManager: AppManager
    
    var body: some View {
        List {
            Text("vroom 😎🦊")
            Button("Reboot") {
                let msg = self.appManager.messageManager.ninebotWrite(StockNBMessage.powerOff(false), ack: false)
                var send = false
                self.appManager.write(msg) {
                    send.toggle()
                    return send
                }
            }
            Text("")
        }
    }
}
