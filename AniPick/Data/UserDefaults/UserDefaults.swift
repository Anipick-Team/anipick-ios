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
    case email
    
    case seasonYear
    case seasonQuater
    case animeGenres
    case animeType
    
    case lastVisitedAnime
    
    case imageId
    
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
    
    func getEmail() -> String {
        return defaults.string(forKey: UserDefaultKey.email.rawValue) ?? "--"
    }
    
    func setNickname(_ nickname: String) {
        defaults.set(nickname, forKey: UserDefaultKey.nickname.rawValue)
    }
    
    func setEmail(_ email: String) {
        defaults.set(email, forKey: UserDefaultKey.email.rawValue)
    }
}


extension UserDefaultsManager {
    func setMetaDataForSeasonYear(_ seasonYear: [Int]) {
        defaults.set(seasonYear, forKey: UserDefaultKey.seasonYear.rawValue)
    }
    
    func setMetaDataForType(_ type: [String]) {
        defaults.set(type, forKey: UserDefaultKey.animeType.rawValue)
    }
    
    func setMetaDataForGenres(_ genres: [Genre]) {
        if let genreData = try? JSONEncoder().encode(genres) {
            defaults.set(genreData, forKey: UserDefaultKey.animeGenres.rawValue)
        }
    }
    
    func setMetaDataForSeason(_ season: [Season]) {
        if let seasonData = try? JSONEncoder().encode(season) {
            defaults.set(seasonData, forKey: UserDefaultKey.seasonQuater.rawValue)
        }
    }
    
    func getMetaDataForSeasonYear() -> [Int] {
        return defaults.object(forKey: UserDefaultKey.seasonYear.rawValue) as? [Int] ?? []
    }
    
    func getMetaDataForType() -> [String] {
        return defaults.object(forKey: UserDefaultKey.animeType.rawValue) as? [String] ?? []
    }
    
    func getMetaDataForGenres() -> [Genre] {
        if let data = defaults.data(forKey: UserDefaultKey.animeGenres.rawValue),
           let genres = try? JSONDecoder().decode([Genre].self, from: data) {
            return genres
        }
        return []
    }
    
    func getMetaDataForSeason() -> [Season] {
        if let data = defaults.data(forKey: UserDefaultKey.seasonQuater.rawValue),
           let seasonQuater = try? JSONDecoder().decode([Season].self, from: data) {
            return seasonQuater
        }
        
        return []
    }
    
    func setLastVisitedAnimeId(animeId: Int) {
        defaults.set(animeId, forKey: UserDefaultKey.lastVisitedAnime.rawValue)
    }
    
    func getLastVisitedAnimeId() -> Int {
        return defaults.integer(forKey: UserDefaultKey.lastVisitedAnime.rawValue)
    }
    
    func logoutAllClearInfo() {
        self.setAccessToken(accessToken: "")
        self.setRefreshToken(refreshToken: "")
        self.setNickname("")
        self.setEmail("")
    }
    
    func setImageId(imageId: Int) {
        defaults.set(imageId, forKey: UserDefaultKey.imageId.rawValue)
    }
    
    func getImageId() -> Int {
        return defaults.integer(forKey: UserDefaultKey.imageId.rawValue)
    }
}

