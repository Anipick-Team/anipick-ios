//
//  UserDefaults.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//
import SwiftUI

enum UserDefaultKey: String {
    case accessToken
    case refreshToken
    case homeRecentKeyword
}

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    private init() {}
}

// MARK: - Auth
extension UserDefaultsManager {
    func setAccessToken(accessToken: String) {
        defaults.set(accessToken, forKey: UserDefaultKey.accessToken.rawValue)
    }
    
    func getAccessToken() -> String {
        return defaults.string(forKey: UserDefaultKey.accessToken.rawValue) ?? ""
    }
    
    func setRefreshToken(refreshToken: String) {
        defaults.set(refreshToken, forKey: UserDefaultKey.refreshToken.rawValue)
    }
    
    func getRefreshToken() -> String {
        return defaults.string(forKey: UserDefaultKey.refreshToken.rawValue) ?? ""
    }
}


// MARK: - Home Recent Keyword
extension UserDefaultsManager {
    func getHomeRecentKeyword() -> [String] {
        return defaults.object(forKey: UserDefaultKey.homeRecentKeyword.rawValue) as? [String] ?? []
    }
    
    func setHomeRecentKeyword(keyword: String) {
        var keywords: [String] = defaults.object(forKey: UserDefaultKey.homeRecentKeyword.rawValue) as? [String] ?? []
        keywords.append(keyword)
        defaults.set(keywords, forKey: UserDefaultKey.homeRecentKeyword.rawValue)
    }
    
    func clearHomeRecentKeyword() {
        defaults.removeObject(forKey: UserDefaultKey.homeRecentKeyword.rawValue)
    }
}
