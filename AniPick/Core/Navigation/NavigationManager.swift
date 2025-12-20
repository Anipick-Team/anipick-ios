//
//  NavigationManager.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import SwiftUI

final class NavigationManager: ObservableObject {
    
    static let shared = NavigationManager() // ✅ 싱글톤
    

    @Published var path = NavigationPath()
    
    func push(route: AppRoute) {
        Task { @MainActor in
            print("🔥 pushing route: \(route)")
            path.append(route)
            print("📦 current path: \(path)")
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
    case commingSoonDetail
    case mainLoginView
    case recentReview
    case recommendView(animeId: Int?)
    
    // Setting
    case setting
    case editNickname
    case editEmail
    case editPassword
    case linkedSNS
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
