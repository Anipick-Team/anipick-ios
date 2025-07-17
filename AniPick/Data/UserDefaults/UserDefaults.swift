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
    case nickname
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
    
    func setHomeRecentKeyword(_ keyword: String) {
        var keywords = getHomeRecentKeyword()
        keywords.removeAll(where: { $0 == keyword })
        keywords.insert(keyword, at: 0)              
        defaults.set(keywords, forKey: UserDefaultKey.homeRecentKeyword.rawValue)
    }
    
    func setHomeRecentKeywordList(_ keywordList: [String]) {
        defaults.set(keywordList, forKey: UserDefaultKey.homeRecentKeyword.rawValue)
    }
    
    func clearHomeRecentKeyword() {
        defaults.removeObject(forKey: UserDefaultKey.homeRecentKeyword.rawValue)
    }
}


extension UserDefaultsManager {
    func getNickname() -> String {
        return defaults.string(forKey: UserDefaultKey.nickname.rawValue) ?? "--"
    }
    
    func setNickname(_ nickname: String) {
        defaults.set(nickname, forKey: UserDefaultKey.nickname.rawValue)
    }
}
