//
//  Utilities.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 02/10/2023.
//

import Foundation
import SwiftUI

// for debugging purposes :)
internal func dataToHex(data: Data) -> String {
    // cool stuff: https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
    return data.map { String(format: "%02hhx", $0) }.joined()
}

internal func generateRandom(count: Int) -> Data {
    let randomData = (0 ..< count).map { _ in
        UInt8.random(in: UInt8.min ... UInt8.max)
    }
    
    return Data(randomData)
}

internal func openUrl(url: String) {
    if let url = URL(string: url) {
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        #endif
    }
}

// these data to (u)intx functions REQUIRE to have their sizes checked before
// being used as i can't be bothered to error check at more points in code
// than needed
internal func dataToInt16(_ data: Data) -> Int16 {
    #if _endian(big)
    let data = Data(data.reversed())
    #endif
    let decodedValue = data.withUnsafeBytes { unsafeBytes in
        unsafeBytes.load(as: Int16.self)
    }
    return decodedValue
}

internal func dataToUInt16(_ data: Data) -> UInt16 {
    #if _endian(big)
    let data = Data(data.reversed())
    #endif
    let decodedValue = data.withUnsafeBytes { unsafeBytes in
        unsafeBytes.load(as: UInt16.self)
    }
    return decodedValue
}

internal func dataToUInt32(_ data: Data) -> UInt32 {
    return UInt32((UInt32(dataToUInt16(Data(data)[2..<4])) << 16) + UInt32(dataToUInt16(Data(data)[0..<2])))
}

internal func undatafy(_ value: Int) -> (Data) {
    let lower = UInt8((value & 0x00ff) >> 0)
    let upper = UInt8((value & 0xff00) >> 8)
    
    return Data([lower, upper])
}
