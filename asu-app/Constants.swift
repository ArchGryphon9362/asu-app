//
//  Constants.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 01/10/2023.
//

import Foundation
import CoreBluetooth

let serialServiceUUID   = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
let serialTXCharUUID    = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
let serialRXCharUUID    = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")

let ninebotHeader = Data(hex: "5aa5")
let xiaomiCryptHeader = Data(hex: "55ab")
let xiaomiHeader = Data(hex: "55aa")

let messageFrequency = 0.25

let forceNbCrypto = false

// don't ask me what upnp or avdtp means. got those names from the miauth python library
let xiaoAuthServiceUUID = CBUUID(string: "0000fe95-0000-1000-8000-00805f9b34fb")
let xiaoUPNPCharUUID    = CBUUID(string: "00000010-0000-1000-8000-00805f9b34fb")
//let xiaoKeyCharUUID     = CBUUID(string: "00000014-0000-1000-8000-00805f9b34fb")
let xiaoAVDTPCharUUID   = CBUUID(string: "00000019-0000-1000-8000-00805f9b34fb")

let xiaoCmdGetInfo  = Data(hex: "a2000000")
let xiaoCmdSetKey   = Data(hex: "15000000")
let xiaoCmdSendData = Data(hex: "000000030400")
let xiaoCmdSendDid  = Data(hex: "000000000200")
let xiaoCmdAuth     = Data(hex: "13000000")
let xiaoRcvRdy      = Data(hex: "00000101")
let xiaoRcvOk       = Data(hex: "00000100")
let xiaoRcvTout     = Data(hex: "000001050100")
let xiaoRcvErr      = Data(hex: "000001050300")

let xiaoKeystore = "ASUtility"
let xiaoKeyTag = "xiaomiPairingKey"
