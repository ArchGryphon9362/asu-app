//
//  XiaomiPairing.swift
//  shut-ios
//
//  Created by ArchGryphon9362 on 08/10/2023.
//

import Foundation
import CoreBluetooth

private enum XiaomiAuthState {
    case unpaired
    case receiveInfo
    case sendKey
    case receiveKey
    case sendDid
    case confirm
    case paired
}

class XiaomiPairing {
    var paired: Bool {
        self.authState == .paired
    }
    var awaitingButtonPress: Bool
    
    private var authState: XiaomiAuthState
    private var gotKeyApproval: Bool
    private var dataToSend: Data
    private var remoteInfo: Data
    private var remoteKey: Data
    private var token: Data
    
    private var authGlue: [UInt8]
    private var expectedFrames: Int
    init() {
        self.authState = .unpaired
        self.awaitingButtonPress = false
        self.gotKeyApproval = false
        self.dataToSend = Data()
        self.remoteInfo = Data()
        self.remoteKey = Data()
        self.token = Data()
        
        self.authGlue = []
        self.expectedFrames = 0
    }
    
    func startPairing(_ scooterManager: ScooterManager) {
        guard !self.paired else {
            return
        }
        
        self.authState = .receiveInfo
        scooterManager.scooterBluetooth.write { _, upnpWrite, _ in
            upnpWrite(xiaoCmdGetInfo)
            
            return false
        }
    }
    
    // TODO: if stuck any, disconnect
    func continuePairing(_ scooterManager: ScooterManager, received data: Data, forCharacteristic uuid: CBUUID) {
        if uuid != serialRXCharUUID {
            guard data.count >= 1 else {
                return
            }
            var frame = Int(data[0])
            if data.count >= 2 {
                frame += Int(data[1]) * 0x100
            }
            
            switch(self.authState) {
            case .receiveInfo, .receiveKey:
                if frame == 0 {
                    guard data.count >= 6 else {
                        return
                    }
                    
                    self.expectedFrames = Int(data[0x04]) + 0x100 * Int(data[0x05])
                    self.authGlue = []
                    scooterManager.scooterBluetooth.write { _, _, avdtpWrite in
                        avdtpWrite(xiaoRcvRdy, false)
                        return false
                    }
                } else {
                    if (data.count > 2) {
                        self.authGlue.append(contentsOf: data[2...])
                    }
                }
                
                if frame == self.expectedFrames {
                    scooterManager.scooterBluetooth.write { _, _, avdtpWrite in
                        avdtpWrite(xiaoRcvOk, false)
                        return false
                    }
                    self.handleState(scooterManager, received: Data(self.authGlue), forCharacteristic: uuid)
                }
            case .sendKey, .sendDid: // TODO: if stuck somewhere, disconnect!!
                guard frame == 0 else {
                    print("unknown mi pairing error")
                    return
                }
                
                if data == xiaoRcvRdy {
                    self.awaitingButtonPress = false
                    self.gotKeyApproval = true
                    scooterManager.scooterBluetooth.blockDisconnectUpdates = false
                    scooterManager.scooterBluetooth.write { _, _, avdtpWrite in
                        avdtpWrite(self.dataToSend, true)
                        return false
                    }
                } else if data == xiaoRcvTout {
                    print("send data timeout")
                } else if data == xiaoRcvErr {
                    print("send data unknown error")
                } else if data == xiaoRcvOk {
                    print("sent ok!!")
                    self.handleState(scooterManager, received: data, forCharacteristic: uuid)
                }
            case .confirm:
                self.handleState(scooterManager, received: data, forCharacteristic: uuid)
            default: return
            }
        }
    }
    
    // TODO: make this loop forever until user allows. when loop starts, switch to .pairing
    func handleState(_ scooterManager: ScooterManager, received data: Data, forCharacteristic uuid: CBUUID) {
        switch(self.authState) {
        case .receiveInfo:
            guard uuid == xiaoAVDTPCharUUID else {
                return
            }
            guard data.count >= 4 + 20 else {
                return
            }
            
            self.remoteInfo = data[4...]
            
            guard self.remoteInfo.count == 20 else {
                print("wrong length remote info")
                return
            }
            
            self.authState = .sendKey
            self.dataToSend = scooterManager.scooterCrypto.getMiAuthPublicKey()[1...]
            
            var tryOnce = true
            var waitedIterations = 0
            scooterManager.scooterBluetooth.write { _, upnpWrite, avdtpWrite in
                if tryOnce {
                    tryOnce = false
                    upnpWrite(xiaoCmdSetKey)
                    avdtpWrite(xiaoCmdSendData, false)
                    return true
                }
                if self.gotKeyApproval {
                    return false
                }
                
                waitedIterations += 1
                if waitedIterations >= Int(1 / messageFrequency) {
                    scooterManager.scooterBluetooth.setConnectionState(.pairing)
                    self.awaitingButtonPress = true
                    scooterManager.disconnectFromScooter(updateUi: false)
                    return false
                }
                return true
            }
        case .sendKey:
            self.authState = .receiveKey
        case .receiveKey:
            guard data.count == 64 else {
                print("scooter key of wrong length")
                return
            }
            
            self.remoteKey = Data([0x04] + data.bytes)
            
            guard let did = self.calcDid(scooterManager) else {
                scooterManager.disconnectFromScooter(updateUi: true)
                return
            }
            self.dataToSend = did.0
            self.token = did.1
            
            self.authState = .sendDid
            scooterManager.scooterBluetooth.write { _, _, avdtpWrite in
                avdtpWrite(xiaoCmdSendDid, false)
                return false
            }
        case .sendDid:
            self.authState = .confirm
            scooterManager.scooterBluetooth.write { _, upnpWrite, _ in
                upnpWrite(xiaoCmdAuth)
                return false
            }
        case .confirm:
            self.authState = .paired
            scooterManager.scooterBluetooth.setConnectionState(.connected)
            print("we're mi authenticated!!")
        default: return
        }
    }
    
    func calcDid(_ scooterManager: ScooterManager) -> (Data, Data)? {
        // return nil if exchange somehow failed :shrug:
        guard let derivedKey = scooterManager.scooterCrypto.generateMiSecret(remoteKey: self.remoteKey, salt: nil) else {
            return nil
        }
        let keyData = derivedKey.withUnsafeBytes {
            return Data(Array($0))
        }
        guard keyData.count == 64 else {
            print("symmetric key of wrong length")
            return nil
        }
        
        let token = keyData[0..<12]
        let a = keyData[28..<44]
        
        let did = self.remoteInfo
        guard let didCt = scooterManager.scooterCrypto.encryptDid(key: a, did: did) else {
            return nil
        }
        return (didCt, token)
    }
}
