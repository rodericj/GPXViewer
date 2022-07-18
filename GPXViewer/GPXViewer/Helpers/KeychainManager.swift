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

    func value(for key: String) -> String? {
        keychain.value(forKey: key) as? String
    }
    func clear(key: String) -> Bool {
        keychain.remove(forKey: key)
    }
}
