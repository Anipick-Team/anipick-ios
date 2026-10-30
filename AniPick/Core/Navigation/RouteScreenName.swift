//
//  RouteScreenName.swift
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
    /// 레거시 화면과 같은 이름 — 이관 전후 화면 조회 이벤트가 이어지게 한다 (R14)
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
    /// 레거시 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .write: return "review_write"
        }
    }
}

extension DetailRoute {
    /// 레거시 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .anime: return "anime_detail"
        case .voiceActor: return "voice_actor_detail"
        case .producer: return "producer_detail"
        case .series: return "series_detail"
        case .recommendations: return "recommend"
        case .cast: return "character_voice_actor"
        }
    }
}

extension HomeRoute {
    /// 레거시 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .main: return "home"
        case .search: return "home_search"
        case .recommendations, .similarRecommendations: return "recommend"
        case .comingSoon: return "coming_soon"
        case .weekdayNewAnime: return "weekday_new_anime"
        case .recentReviews: return "recent_review"
        }
    }
}

extension MyInfoRoute {
    /// 레거시 화면 이름 (R14)
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
    /// 레거시 화면 이름 (R14)
    var screenName: String {
        switch self {
        case .main: return "explore"
        case .communityPost: return "community_detail"
        case .communityBoard: return "community"
        case .communityWrite: return "community_write"
        case .communityEdit: return "community_edit"
        // 탐색 화면 안에 들어가는 하위 탭이라 push되지 않는다. 탭 전환은 ContentView가 기록한다
        case .communityBoards: return "explore"
        }
    }
}

extension AuthRoute {
    /// 레거시 화면 이름 (R14)
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
