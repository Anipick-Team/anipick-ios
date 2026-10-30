//
//  UserDefaults.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//
import SwiftUI

import Storage

nonisolated enum UserDefaultKey: String {
    case accessToken
    case refreshToken
    case homeRecentKeyword
    case nickname
    case email
    case sns
    case userId
    // 레거시: 이메일 기반 애플 로그인 시절 저장 키 (로그아웃 시 정리용)
    case appleUserId
    case appleEmail
    
    case lastVisitedAnime

    case imageId

}

/// UserDefaults(스레드 안전 — Apple 문서)·Keychain만 감싸 어느 스레드에서나 부른다 (로그아웃 클로저 등)
nonisolated final class UserDefaultsManager: @unchecked Sendable {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    // 토큰은 Keychain에 저장한다. 이전 버전이 UserDefaults에 저장한 토큰은 앱 시작 시 옮긴다.
    // AppSession도 같은 저장소를 쓴다.
    let tokenStore = AuthTokenStore(
        secureStore: Keychain(service: "com.moana.AniPick.auth"),
        defaults: .standard
    )

    private init() {}
}

// MARK: - Auth
nonisolated extension UserDefaultsManager {
    /// 앱 시작 시 토큰을 읽는 어떤 코드보다 먼저 호출한다 (재설치 정리, UserDefaults 토큰 이관).
    func prepareTokenStorage() {
        tokenStore.prepareOnLaunch()
    }

    func setAccessToken(accessToken: String) {
        tokenStore.setAccessToken(accessToken)
    }

    func getAccessToken() -> String {
        return tokenStore.accessToken
    }

    func setRefreshToken(refreshToken: String) {
        tokenStore.setRefreshToken(refreshToken)
    }

    func getRefreshToken() -> String {
        return tokenStore.refreshToken
    }
    
    // 값이 있으면 sns로 가입된 것, 빈 값이면 이메일로그인
    func setSNSAccount(sns: String) {
        defaults.set(sns, forKey: UserDefaultKey.sns.rawValue)
    }
    
    func getSNSAccount() -> String {
        return defaults.string(forKey: UserDefaultKey.sns.rawValue) ?? ""
    }

    // 서버 내부 userId. 로그인 응답에 없으면 지운다 (이전 계정 값이 남지 않도록)
    func setUserId(_ userId: Int?) {
        if let userId {
            defaults.set(userId, forKey: UserDefaultKey.userId.rawValue)
        } else {
            defaults.removeObject(forKey: UserDefaultKey.userId.rawValue)
        }
    }

    func getUserId() -> Int? {
        return defaults.object(forKey: UserDefaultKey.userId.rawValue) as? Int
    }
}


// MARK: - Home Recent Keyword
nonisolated extension UserDefaultsManager {
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


nonisolated extension UserDefaultsManager {
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


nonisolated extension UserDefaultsManager {
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
        self.setUserId(nil)
        defaults.removeObject(forKey: UserDefaultKey.appleUserId.rawValue)
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
}
