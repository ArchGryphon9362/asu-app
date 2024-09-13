//
//  XiaomiAuth.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 06/01/2024.
//

import Foundation
import CoreBluetooth

private enum XiaomiAuthStep {
    case start
    case receiveInfo
    case sendKey
    case receiveKey
    case sendDid
    case confirm
    case done
}

private enum XiaomiAuthState {
    case unauthenticated
    case registering(XiaomiAuthStep)
    case loggingIn(XiaomiAuthStep)
    case authenticated
}

class XiaomiAuth {
    private var authState: XiaomiAuthState
    private var xiaomiCrypto: XiaomiCrypto
    
    // TODO: remove placeholder
    var awaitingButtonPress = true
    
    var authenticated: Bool {
        get {
            switch self.authState {
            case .authenticated: true
            default: false
            }
        }
    }
    
    init(xiaomiCrypto: XiaomiCrypto) {
        self.authState = .unauthenticated
        self.xiaomiCrypto = xiaomiCrypto
//        self.authState = .unauthenticated
//        self.awaitingButtonPress = false
//        self.gotKeyApproval = false
//        self.dataToSend = Data()
//        
//        self.authGlue = []
//        self.expectedFrames = 0
    }
    
    func startAuthenticating(withScooterManager appManager: AppManager) {
        print("no we not starting lol")
    }
    
    func continueAuthenticating(withScooterManager appManager: AppManager, received data: Data, forCharacteristic uuid: CBUUID) {
        print("lol fr?")
    }
}
