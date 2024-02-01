//
//  Settings.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 31/01/2024.
//

import Foundation
import SwiftUI

let appSettings = Settings()

class Settings: ObservableObject {
    // main
    @AppStorage("correctSpeedUnits") var correctSpeedUnits = Locale.current.usesMetricSystem
    
    // advanced
    @AppStorage("mismatchedFirmware") var mismatchedFirmware = false
    @AppStorage("increasedAmps") var increasedAmps = false
    @AppStorage("shfwAdvanced") var shfwAdvanced = false
    
    // secret lair
    @AppStorage("allowForceNbCrypto") var allowForceNbCrypto = false
    @AppStorage("foxMode") var foxMode = false
    
    fileprivate init() { }
}
