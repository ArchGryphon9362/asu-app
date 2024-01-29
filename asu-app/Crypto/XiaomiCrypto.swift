// This helped greatly with the implementation: https://github.com/dnandha/miauth/blob/main/lib/python/miauth/mi/micrypto.py
//
//  XiaomiCrypto.swift
//  asu-app
//
//  Created by ArchGryphon9362 on 03/10/2023.
//

import Foundation
import CryptoSwift
import CryptoKit

fileprivate enum Keypair {
    case secKey(SecKey, Data)
    case simpleKey(P256.KeyAgreement.PrivateKey, Data)
}

fileprivate struct EncryptionKeys {
    let deviceKey: Data
    let appKey: Data
    
    let deviceIv: Data
    let appIv: Data
}

enum SharedKey {
    case sharedSecret(SharedSecret)
    case data(Data)
}

// TODO: make sure fallback crypto works
class XiaomiCrypto {
    private var keypair: Keypair
    private var encryptionKeys: EncryptionKeys?
    private var remoteInfo: Data
    private var remoteKey: Data
    private var token: Data
    
    private var counter: UInt32
    
    private static func generateKeypair() -> SecKey? {
        var error: Unmanaged<CFError>?
        
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleAfterFirstUnlock,
            .privateKeyUsage,
            &error
        ), error == nil else {
            return nil
        }
        
        let keyAttributes: NSDictionary = [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrTokenID: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs: [
                kSecAttrIsPermanent: true,
                kSecAttrApplicationTag: xiaoKeyTag,
                kSecAttrAccessControl: accessControl
            ] as [String: Any]
        ]
        
        guard let privateKey = SecKeyCreateRandomKey(keyAttributes, &error), error == nil else {
            return nil
        }
        
        let storeQuery: NSDictionary = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationLabel: xiaoKeystore,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecUseDataProtectionKeychain: true,
            kSecValueRef: privateKey
        ]
        let storeStatus = SecItemAdd(storeQuery, nil)
        if storeStatus != errSecSuccess {
            print("failed to store miauth key. won't persist")
        }
        
        return privateKey
    }
    
    init() {
        self.remoteInfo = Data()
        self.remoteKey = Data()
        self.token = Data()
        
        self.counter = 0
        
        var privateKey: SecKey?
        var publicKey: Data?
        
        var error: Unmanaged<CFError>?
        
        let query: NSDictionary = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationLabel: xiaoKeystore,
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecUseDataProtectionKeychain: true,
            kSecReturnRef: true
        ]
        
        var result: CFTypeRef?
        switch(SecItemCopyMatching(query, &result)) {
        case errSecSuccess:
            privateKey = (result as! SecKey)
        case errSecItemNotFound: privateKey = Self.generateKeypair()
        default: break
        }
        
        if let privateKey = privateKey {
            if let publicSecKey = SecKeyCopyPublicKey(privateKey) {
                if let publicKeyData = SecKeyCopyExternalRepresentation(publicSecKey, &error), error == nil {
                    publicKey = publicKeyData as Data
                }
            }
        }
        
        
        // setup fallback key in case persistent one somehow failed to generate
        guard let privateKey = privateKey, let publicKey = publicKey else {
            let simplePrivateKey = P256.KeyAgreement.PrivateKey()
            print("mi auth public key: \(dataToHex(data: simplePrivateKey.publicKey.x963Representation))")
            self.keypair = .simpleKey(simplePrivateKey, simplePrivateKey.publicKey.x963Representation)
            return
        }
        
        print("mi auth public key: \(dataToHex(data: publicKey))")
        self.keypair = .secKey(privateKey, publicKey)
    }
    
    func reset() {
        // TODO: remove this log
        print("micrypto reset")
        self.encryptionKeys = nil
        self.remoteInfo = Data()
        self.remoteKey = Data()
        self.token = Data()
        self.counter = 0
    }
    
    func getPublicKey(withRemoteInfo remoteInfo: Data) -> Data {            
        if remoteInfo.count != 20 {
            print("wrong length remote info: \(remoteInfo.bytes)")
        } else {
            self.remoteInfo = remoteInfo
            print("beep :)")
        }
        
        switch(self.keypair) {
        case let .secKey(_, publicKey): return publicKey
        case let .simpleKey(_, publicKey): return publicKey
        }
    }
    
    func generateSecret(withRemoteKey remoteKey: Data) -> SharedKey? {
        guard remoteKey.count == 65 else {
            return nil
        }
        
        switch(self.keypair) {
        case let .secKey(privateKey, _):
            var error: Unmanaged<CFError>?
            
            let publicAttributes: NSDictionary = [
                kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeyClass: kSecAttrKeyClassPublic,
            ]
            guard let remoteSecKey = SecKeyCreateWithData(remoteKey as CFData, publicAttributes, nil) else {
                return nil
            }
            let sharedKey = SecKeyCopyKeyExchangeResult(privateKey, .ecdhKeyExchangeStandard, remoteSecKey, [:] as CFDictionary, &error)
            guard let sharedKey = sharedKey, error == nil else {
                return nil
            }
            
            return .data(sharedKey as Data)
            
        case let .simpleKey(privateKey, _):
            guard let remotePublicKey = try? P256.KeyAgreement.PublicKey(x963Representation: remoteKey) else {
                return nil
            }
            
            guard let sharedKey = try? privateKey.sharedSecretFromKeyAgreement(with: remotePublicKey) else {
                return nil
            }
            
            return .sharedSecret(sharedKey)
        }
    }
    
    private func deriveKey(withSharedKey sharedKey: SharedKey, withSalt salt: Data?) -> SymmetricKey? {
        var info = Data("mible-login-info".bytes)
        if salt == nil {
            info = Data("mible-setup-info".bytes)
        }
        let salt = salt ?? Data()
        
        switch(sharedKey) {
        case let .data(key):
            let symmetricKey = CryptoKit.HKDF<SHA256>.deriveKey(
                inputKeyMaterial: .init(data: key as Data),
                salt: salt,
                info: info,
                outputByteCount: 64
            )
            
            return symmetricKey
        case let .sharedSecret(key):
            let symmetricKey = key.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: salt,
                sharedInfo: info,
                outputByteCount: 64
            )
            
            return symmetricKey
        }
    }
    
    func calculateDid(withRemoteKey remoteKey: Data) -> Data? {
        guard remoteKey.count == 65 else {
            return nil
        }
        
        self.remoteKey = remoteKey
        guard let sharedKey = self.generateSecret(withRemoteKey: self.remoteKey) else {
            return nil
        }
        guard let derivedKey = self.deriveKey(withSharedKey: sharedKey, withSalt: nil) else {
            return nil
        }
        let keyData = derivedKey.withUnsafeBytes {
            return Data(Array($0))
        }
        guard keyData.count == 64 else {
            print("symmetric key of wrong length")
            return nil
        }
        
        self.token = keyData[0..<12]
        let a = keyData[28..<44]
        
        let did = self.remoteInfo
        let ccm = CryptoSwift.CCM(iv: Array(16..<28), tagLength: 4, messageLength: did.count, additionalAuthenticatedData: "devID".bytes)
        guard let didEncrypted = try? CryptoSwift.AES(key: a.bytes, blockMode: ccm).encrypt(did.bytes) else {
            return nil
        }
        return Data(didEncrypted)
    }
    
    // TODO: this is bork. (missing half the logic, fik)
    func calculateEncryptionKeys(keys: Data) -> (info: Data, expectedRemoteInfo: Data)? {
        guard keys.count >= 40 else {
            return nil
        }
        
        self.encryptionKeys = .init(
            deviceKey: keys[..<16],
            appKey: keys[16..<32],
            deviceIv: keys[32..<36],
            appIv: keys[36..<40]
        )
        
        return nil // TODO: oof
    }
    
    func crc16(_ data: Data) -> Data {
        var crc = 0
        for value in data {
            crc += Int(value)
        }
        crc = ~crc
        var final = Data()
        final.append(UInt8((crc & 0x00ff) >> 0))
        final.append(UInt8((crc & 0xff00) >> 8))
        return final
    }
    
    func encrypt(_ data: Data) -> Data? {
        guard let encryptionKeys = self.encryptionKeys else {
            // encryption keys not derived yet :)
            print(1)
            return nil
        }
        
        guard data.count >= 3 else {
            print(2)
            return nil
        }
        
        guard data.starts(with: xiaomiHeader) else {
            print(3)
            return nil
        }
        
        let length = data[2]
        let payload = data[3...] + generateRandom(count: 4)
        
        let counter = Data(bytes: &self.counter, count: 4)
        let nonce = encryptionKeys.appIv
        let iv = nonce + Data(count: 4) + counter
        
        let blockMode = CCM(iv: iv.bytes, tagLength: 4, messageLength: payload.count)
        guard let encryptedPayload = try? AES(key: encryptionKeys.appKey.bytes, blockMode: blockMode, padding: .noPadding).encrypt(payload.bytes) else {
            // encrypt or init aes failed
            print(5)
            return nil
        }
        
        var newData = Data()
        newData.append(length)
        newData.append(contentsOf: counter.prefix(2))
        newData.append(contentsOf: encryptedPayload)
        
        var result = Data()
        result.append(contentsOf: xiaomiCryptHeader)
        result.append(contentsOf: newData)
        result.append(contentsOf: self.crc16(newData))
        
        print("[XiaomiCrypto] Encrypted - \(dataToHex(data: result))")
        return result
    }
    
    func decrypt(_ data: Data) -> Data? {
        guard let encryptionKeys = self.encryptionKeys else {
            // encryption keys not derived yet :)
            print(6)
            return nil
        }
        
        guard data.count >= 8 else {
            print(7)
            return nil
        }
        
        guard data.starts(with: xiaomiCryptHeader) else {
            print(8)
            return nil
        }
        
        let counter = data[3..<5]
        let encryptedPayload = data[3..<data.count - 2]
        
        let nonce = encryptionKeys.appIv
        let iv = nonce + Data(count: 4) + counter + Data(count: 2)
        
        let blockMode = CCM(iv: iv.bytes, tagLength: 4, messageLength: encryptedPayload.count)
        guard let decryptedPayload = try? AES(key: encryptionKeys.appKey.bytes, blockMode: blockMode, padding: .noPadding).decrypt(encryptedPayload.bytes) else {
            // encrypt or init aes failed
            print(9)
            return nil
        }
        
        var result = Data()
        result.append(contentsOf: xiaomiHeader)
        result.append(data[2])
        result.append(contentsOf: decryptedPayload)

        print("[XiaomiCrypto] Decrypted - \(dataToHex(data: result))")
        return result
    }
}
