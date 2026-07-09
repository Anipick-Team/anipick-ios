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
    case sns
    case appleUserId
    case appleEmail
    
    case seasonYear
    case seasonQuater
    case animeGenres
    case animeType
    
    case lastVisitedAnime

    case imageId

    case hasSeenServerRecoveryNotice

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
    
    // 값이 있으면 sns로 가입된 것, 빈 값이면 이메일로그인
    func setSNSAccount(sns: String) {
        defaults.set(sns, forKey: UserDefaultKey.sns.rawValue)
    }
    
    func getSNSAccount() -> String {
        return defaults.string(forKey: UserDefaultKey.sns.rawValue) ?? ""
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
        return defaults.string(forKey: UserDefaultKey.email.rawValue) ?? ""
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
        // 인증 토큰
        self.setAccessToken(accessToken: "")
        self.setRefreshToken(refreshToken: "")
        // 유저 프로필
        self.setNickname("")
        self.setEmail("")
        self.setImageId(imageId: 0)
        // SNS 연동 정보
        self.setSNSAccount(sns: "")
        self.setAppleUserId("")
        defaults.removeObject(forKey: UserDefaultKey.appleEmail.rawValue)
        // 유저 활동 기록
        self.clearHomeRecentKeyword()
        defaults.removeObject(forKey: UserDefaultKey.lastVisitedAnime.rawValue)
    }
    
    func setImageId(imageId: Int) {
        defaults.set(imageId, forKey: UserDefaultKey.imageId.rawValue)
    }
    
    func getImageId() -> Int {
        return defaults.integer(forKey: UserDefaultKey.imageId.rawValue)
    }
    
    func setAppleUserId(_ value: String) {
        defaults.set(value, forKey: UserDefaultKey.appleUserId.rawValue)
    }
    
    func getAppleUserId() -> String {
        return defaults.string(forKey: UserDefaultKey.appleUserId.rawValue) ?? ""
    }
}

// MARK: - 공지
extension UserDefaultsManager {
    // 서버 복구 안내 팝업을 이미 확인했는지 여부 (로그아웃해도 유지)
    func setHasSeenServerRecoveryNotice(_ value: Bool) {
        defaults.set(value, forKey: UserDefaultKey.hasSeenServerRecoveryNotice.rawValue)
    }

    func getHasSeenServerRecoveryNotice() -> Bool {
        return defaults.bool(forKey: UserDefaultKey.hasSeenServerRecoveryNotice.rawValue)
    }
}

