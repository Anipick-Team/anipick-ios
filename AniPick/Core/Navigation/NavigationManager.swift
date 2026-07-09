//
//  NavigationManager.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import SwiftUI

@MainActor
final class NavigationManager: ObservableObject {

    @Published var path = NavigationPath()
    // 로그인 여부 (루트 화면 게이팅). push 유실과 무관하게 로그인 완료를 보장하기 위한 공유 상태.
    @Published var isLoggedIn: Bool = !UserDefaultsManager.shared.getAccessToken().isEmpty

    /// 로그인 성공 시 호출. nav push에 의존하지 않고 즉시 루트를 홈(로그인 상태)으로 전환한다.
    func completeLogin() {
        let tokenLength = UserDefaultsManager.shared.getAccessToken().count
        DLog("🔐 [Login] completeLogin 호출 - accessToken 길이=\(tokenLength)")
        if tokenLength == 0 {
            DLog("⚠️ [Login] completeLogin 시점에 accessToken이 비어있음 - 서버 응답 확인 필요")
        }
        path = NavigationPath()   // 스택 초기화 → 홈이 루트로
        isLoggedIn = true
        DLog("🔐 [Login] isLoggedIn=true 전환 완료, path 초기화")
    }

    /// 로그아웃/탈퇴 시 호출. 루트를 로그인 화면으로 되돌린다.
    func completeLogout() {
        DLog("🔐 [Login] completeLogout 호출 - isLoggedIn=false 전환, path 초기화")
        path = NavigationPath()
        isLoggedIn = false
    }

    func push(route: AppRoute) {
        Task { @MainActor in
            DLog("🔥 pushing route: \(route)")
            path.append(route)
            DLog("📦 current path: \(path)")
        }
    }
    
    func pop() {
        Task { @MainActor in
            path.removeLast()
        }
    }
    
    func popToRoot() {
        Task { @MainActor in
            path.removeLast(path.count)
        }
    }
}


enum AppRoute: Hashable {
    case homeView
    case emailLogin
    case LoginProblem
    case emailSignup
    case findPassword
    case successLogin
    case homeSearch
    case ranking
    case research
    case review(starRating: Double, animeId: Int, reviewContent: String)
    case explore(season: Int?, seasonYear: Int?)
    case animeDetail(animeId: Int)
    case resetPassword
    case preferenceSelection
    case content(activeTab: Tab)
    case comingSoonDetail
    case mainLoginView
    case recentReview
    case recommendView(animeId: Int?)
    case recommend2(animeId: Int, animeTitle: String?)
    
    // Setting
    case setting
    case editNickname
    case editEmail
    case editPassword
    case linkedSNS
    case adultCheck
    case adultSetting
    case appVersion
    case inquiry
    case termsOfService
    case privacyPolicy
    case notice
    case logout
    case deleteAccount

    // MyInfo
    case myInfo
    case myInfoInToWatchList
    case myInfoWatchingList
    case finishedWatchList
    case likeAnimeList
    case likePersonList
    case ratedAnimeList
    
    case producerDetail(studioId: Int)
    case voiceActorDetail(animeId: Int)
    case characterAndVoiceActorDetail(animeId: Int)
    case seriesDetail(animeId: Int, animeTitle: String)
    case recommend(animeId: Int, animeTitle: String)
    
}
