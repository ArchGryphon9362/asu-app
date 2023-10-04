//
//  Constants.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import Foundation
import CoreBluetooth

let serialServiceUUID   = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
let serialTXCharUUID    = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
let serialRXCharUUID    = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")

// don't ask me what upnp or avdtp means. got those names from the miauth python library
let xiaoAuthServiceUUID = CBUUID(string: "0000fe95-0000-1000-8000-00805f9b34fb")
let xiaoUPNPCharUUID    = CBUUID(string: "00000010-0000-1000-8000-00805f9b34fb")
//let xiaoKeyCharUUID     = CBUUID(string: "00000014-0000-1000-8000-00805f9b34fb")
let xiaoAVDTPCharUUID   = CBUUID(string: "00000019-0000-1000-8000-00805f9b34fb")

let ninebotHeader = Data(hex: "5aa5")
