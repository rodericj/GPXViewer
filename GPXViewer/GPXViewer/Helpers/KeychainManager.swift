//
//  KeychainManager.swift
//  GPXViewer
//
//  Created by Roderic Campbell on 7/17/22.
//

import Keychain

struct KeychainManager {
    let keychain = Keychain()
    func set(value: String, for key: String) -> Bool {
        keychain.save(value, forKey: key)
    }

    func clear(key: String) -> Bool {
        keychain.remove(forKey: key)
    }
}
