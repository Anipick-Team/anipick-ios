//
//  NavigationManager.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import AuthInterface
import DetailInterface
import ExploreInterface
import HomeInterface
import MyInfoInterface
import ReviewInterface
import SettingInterface
import SwiftUI
import Utils

@MainActor
final class NavigationManager: ObservableObject {

    @Published var path = NavigationPath()
    // 로그인 여부 (루트 화면 게이팅). push 유실과 무관하게 로그인 완료를 보장하기 위한 공유 상태.
    @Published var isLoggedIn: Bool = !UserDefaultsManager.shared.getAccessToken().isEmpty
    // 새 Feature 화면을 모달로 띄울 때 (LegacyNavigator.present). AppEntryView가 sheet로 표시한다.
    @Published var presentedRoute: PresentedRoute?

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
        AnalyticsManager.clearUser()
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
    case weekdayNewAnime(day: Int)
    case mainLoginView
    case recentReview
    case recommendView(animeId: Int?)
    case recommend2(animeId: Int, animeTitle: String?)

    // Community
    case community(seriesId: Int, animeTitle: String, coverImageUrl: String?, genreNames: [String])
    case communityDetail(postId: Int)
    case communityWrite(seriesId: Int, animeTitle: String)
    case communityEdit(postId: Int, seriesId: Int, animeTitle: String, title: String, content: String, isSpoiler: Bool, imageIds: [Int])
    
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
    case myContent

    case producerDetail(studioId: Int)
    case voiceActorDetail(animeId: Int)
    case characterAndVoiceActorDetail(animeId: Int)
    case seriesDetail(animeId: Int, animeTitle: String)
    case recommend(animeId: Int, animeTitle: String)
    
}

// MARK: - Analytics 화면 이름
extension AppRoute {
    /// screen_view 이벤트에 쓰는 화면 이름. nil이면 그 화면이 직접 기록한다 (탭 화면).
    var screenName: String? {
        switch self {
        case .homeView: return "home"
        case .emailLogin: return "email_login"
        case .LoginProblem: return "login_problem"
        case .emailSignup: return "email_signup"
        case .findPassword: return "find_password"
        case .successLogin: return "success_login"
        case .homeSearch: return "home_search"
        case .ranking: return "ranking"
        case .research: return "research"
        case .review: return "review_write"
        case .explore: return "explore"
        case .animeDetail: return "anime_detail"
        case .resetPassword: return "reset_password"
        case .preferenceSelection: return "preference_selection"
        case .content: return nil
        case .comingSoonDetail: return "coming_soon"
        case .weekdayNewAnime: return "weekday_new_anime"
        case .mainLoginView: return "login"
        case .recentReview: return "recent_review"
        case .recommendView, .recommend2, .recommend: return "recommend"
        case .community: return "community"
        case .communityDetail: return "community_detail"
        case .communityWrite: return "community_write"
        case .communityEdit: return "community_edit"
        case .setting: return "setting"
        case .editNickname: return "edit_nickname"
        case .editEmail: return "edit_email"
        case .editPassword: return "edit_password"
        case .linkedSNS: return "linked_sns"
        case .adultCheck: return "adult_check"
        case .adultSetting: return "adult_setting"
        case .appVersion: return "app_version"
        case .inquiry: return "inquiry"
        case .termsOfService: return "terms_of_service"
        case .privacyPolicy: return "privacy_policy"
        case .notice: return "notice"
        case .logout: return "logout"
        case .deleteAccount: return "delete_account"
        case .myInfo: return "my_info"
        case .myInfoInToWatchList: return "my_to_watch_list"
        case .myInfoWatchingList: return "my_watching_list"
        case .finishedWatchList: return "my_finished_list"
        case .likeAnimeList: return "my_liked_anime"
        case .likePersonList: return "my_liked_person"
        case .ratedAnimeList: return "my_rated_anime"
        case .myContent: return "my_content"
        case .producerDetail: return "producer_detail"
        case .voiceActorDetail: return "voice_actor_detail"
        case .characterAndVoiceActorDetail: return "character_voice_actor"
        case .seriesDetail: return "series_detail"
        }
    }
}

extension Tab {
    var screenName: String {
        switch self {
        case .home: return "home"
        case .ranking: return "ranking"
        case .research: return "explore"
        case .myInfo: return "my_info"
        }
    }
}

extension SettingRoute {
    /// 레거시 `AppRoute.screenName`과 같은 이름 — 이관 전후 화면 조회 이벤트가 이어지게 한다 (R14)
    var screenName: String {
        switch self {
        case .main: return "setting"
        case .editNickname: return "edit_nickname"
        case .withdrawal: return "delete_account"
        case .editPassword: return "edit_password"
        case .editEmail: return "edit_email"
        }
    }
}

extension ReviewRoute {
    /// 레거시 `AppRoute.review`의 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .write: return "review_write"
        }
    }
}

extension DetailRoute {
    /// 레거시 `AppRoute.animeDetail`의 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .anime: return "anime_detail"
        case .voiceActor: return "voice_actor_detail"
        }
    }
}

extension HomeRoute {
    /// 레거시 `AppRoute.homeSearch`의 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .search: return "home_search"
        }
    }
}

extension MyInfoRoute {
    /// 레거시 `AppRoute`의 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .main: return "my_info"
        case .watchList: return "my_to_watch_list"
        case .watching: return "my_watching_list"
        case .finished: return "my_finished_list"
        case .likedAnimes: return "my_liked_anime"
        case .likedPersons: return "my_liked_person"
        case .ratedReviews: return "my_rated_anime"
        case .myContent: return "my_content"
        }
    }
}

extension ExploreRoute {
    /// 레거시 `AppRoute.communityDetail`의 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .communityPost: return "community_detail"
        case .communityBoard: return "community"
        // 탐색 화면 안에 들어가는 하위 탭이라 push되지 않는다. 탭 전환은 ContentView가 기록한다
        case .communityBoards: return "explore"
        }
    }
}

extension AuthRoute {
    /// 레거시 `AppRoute`의 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .emailLogin: return "email_login"
        case .emailSignup: return "email_signup"
        case .findPassword: return "find_password"
        case .loginProblem: return "login_problem"
        case .preferenceSelection: return "preference_selection"
        case .resetPassword: return "reset_password"
        case .mainLogin: return "login"
        }
    }
}
