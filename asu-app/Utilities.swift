//
//  Utilities.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 02/10/2023.
//

import Foundation

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
