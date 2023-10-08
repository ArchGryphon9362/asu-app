// This helped greatly with the implementation: https://github.com/dnandha/miauth/blob/main/lib/python/miauth/mi/micrypto.py
//
//  XiaomiCrypto.swift
//  shut-ios
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

// TODO: make sure fallback crypto works
class XiaomiCrypto {
    private var keypair: Keypair
    
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
            self.keypair = .simpleKey(simplePrivateKey, simplePrivateKey.x963Representation)
            return
        }
        
        self.keypair = .secKey(privateKey, publicKey)
    }
    
    func getPublicKey() -> Data {
        switch(self.keypair) {
        case let .secKey(_, publicKey): return publicKey
        case let .simpleKey(_, publicKey): return publicKey
        }
    }
    
    func generateSecret(remoteKey: Data, salt: Data?) -> SymmetricKey? {
        guard remoteKey.count == 65 else {
            return nil
        }
        
        var info = Data("mible-login-info".bytes)
        if salt == nil {
            info = Data("mible-setup-info".bytes)
        }
        let salt = salt ?? Data()
        
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
            
            let symmetricKey = CryptoKit.HKDF<SHA256>.deriveKey(inputKeyMaterial: .init(data: sharedKey as Data), salt: salt, info: info, outputByteCount: 64)
            return symmetricKey
            
        case let .simpleKey(privateKey, _):
            guard let remotePublicKey = try? P256.KeyAgreement.PublicKey(x963Representation: remoteKey) else {
                return nil
            }
            
            guard let sharedKey = try? privateKey.sharedSecretFromKeyAgreement(with: remotePublicKey) else {
                return nil
            }
            
            let symmetricKey = sharedKey.hkdfDerivedSymmetricKey(using: SHA256.self, salt: salt, sharedInfo: info, outputByteCount: 64)
            return symmetricKey
        }
    }
    
    func encryptDid(key: Data, did: Data) -> Data? {
        let ccm = CryptoSwift.CCM(iv: [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27], tagLength: 4, messageLength: 20, additionalAuthenticatedData: "devID".bytes)
        guard let aes = try? CryptoSwift.AES(key: key.bytes, blockMode: ccm) else {
            return nil
        }
        guard let didCt = try? Data(aes.encrypt(did.bytes)) else {
            return nil
        }
        return didCt
    }
}
