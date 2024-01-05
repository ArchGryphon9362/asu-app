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
    let deviceKey: Data?
    let appKey: Data?
    
    let deviceIv: Data?
    let appIv: Data?
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
    
    func getPublicKey(withRemoteInfo remoteInfo: Data) -> Data {            
        if self.remoteInfo.count != 20 {
            print("wrong length remote info")
        } else {
            self.remoteInfo = remoteInfo
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
        let ccm = CryptoSwift.CCM(iv: [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27], tagLength: 4, messageLength: 20, additionalAuthenticatedData: "devID".bytes)
        guard let aes = try? CryptoSwift.AES(key: a.bytes, blockMode: ccm) else {
            return nil
        }
        guard let didEncrypted = try? Data(aes.encrypt(did.bytes)) else {
            return nil
        }
        return didEncrypted
    }
    
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
    
//    func encrypt(data: Data) -> Data? {
//        guard data.count >= 3 else {
//            return nil
//        }
//        
//        guard data[0] == 0x55, data[1] == 0xAB else {
//            return nil
//        }
//        
//        let length = data[2]
//        let data = data[3...]
//    }
//    
//    func decrypt(data: Data) -> Data? {
//        
//    }
}
