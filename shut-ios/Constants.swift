//
//  Constants.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import Foundation
import CoreBluetooth

let discoveryServiceUUID = CBUUID(string: "fe95")
let serialServiceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
let serialTXCharUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
let serialRXCharUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")

let msgHeader = Data(hex: "55ab")
