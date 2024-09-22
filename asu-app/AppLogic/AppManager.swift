//
//  AppManager.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 25/09/2023.
//

import SwiftUI
import Foundation
import CoreBluetooth
import OrderedCollections
import CryptoKit

class AppManager : ObservableObject {
    @Published var scooter: Scooter = .init()
}
