//
//  RouteScreenNameTests.swift
//  AniPickTests
//
//  Route의 화면 조회 이름이 레거시 AppRoute가 쓰던 이름과 같은지 (R14).
//  레거시 AppRoute는 Phase 5에서 지웠으므로, 그때의 이름을 문자열로 고정한다.
//

import AuthInterface
import DetailInterface
import ExploreInterface
import HomeInterface
import MyInfoInterface
import ReviewInterface
import SettingInterface
import Testing

@testable import AniPick

@MainActor
@Suite("Route 화면 이름 = 레거시 이름")
struct RouteScreenNameTests {
    @Test(
        "설정 Route",
        arguments: [
            (SettingRoute.main, "setting"), (.editNickname, "edit_nickname"),
            (.withdrawal, "delete_account"), (.editPassword, "edit_password"), (.editEmail, "edit_email"),
        ]
    )
    func setting(route: SettingRoute, name: String) {
        #expect(route.screenName == name)
    }

    @Test("리뷰 Route")
    func review() {
        #expect(ReviewRoute.write(animeId: 1, rating: 3, content: "").screenName == "review_write")
    }

    @Test(
        "홈 Route",
        arguments: [
            (HomeRoute.main, "home"), (.search, "home_search"),
            (.recommendations(animeId: 1, animeTitle: nil), "recommend"), (.comingSoon, "coming_soon"),
            (.recentReviews, "recent_review"), (.weekdayNewAnime(day: 1), "weekday_new_anime"),
            (.similarRecommendations(animeId: 1), "recommend"),
        ]
    )
    func home(route: HomeRoute, name: String) {
        #expect(route.screenName == name)
    }

    @Test(
        "마이페이지 Route",
        arguments: [
            (MyInfoRoute.main, "my_info"), (.watchList, "my_to_watch_list"), (.watching, "my_watching_list"),
            (.finished, "my_finished_list"), (.likedAnimes, "my_liked_anime"), (.likedPersons, "my_liked_person"),
            (.ratedReviews, "my_rated_anime"), (.myContent, "my_content"),
        ]
    )
    func myInfo(route: MyInfoRoute, name: String) {
        #expect(route.screenName == name)
    }

    @Test(
        "상세 Route",
        arguments: [
            (DetailRoute.anime(id: 1), "anime_detail"), (.voiceActor(id: 1), "voice_actor_detail"),
            (.producer(id: 1), "producer_detail"), (.cast(animeId: 1), "character_voice_actor"),
            (.series(animeId: 1, animeTitle: ""), "series_detail"),
            (.recommendations(animeId: 1, animeTitle: ""), "recommend"),
        ]
    )
    func detail(route: DetailRoute, name: String) {
        #expect(route.screenName == name)
    }

    @Test(
        "탐색·커뮤니티 Route",
        arguments: [
            (ExploreRoute.main, "explore"), (.communityPost(id: 1), "community_detail"),
            (.communityBoard(seriesId: 1, animeTitle: "", coverImageUrl: nil, genreNames: []), "community"),
            (.communityWrite(seriesId: 1, animeTitle: ""), "community_write"),
            (
                .communityEdit(
                    postId: 1, seriesId: 1, animeTitle: "", title: "", content: "", isSpoiler: false, imageIds: []),
                "community_edit"
            ),
        ]
    )
    func explore(route: ExploreRoute, name: String) {
        #expect(route.screenName == name)
    }

    @Test(
        "로그인 Route",
        arguments: [
            (AuthRoute.emailLogin, "email_login"), (.emailSignup, "email_signup"),
            (.findPassword, "find_password"), (.loginProblem, "login_problem"),
            (.preferenceSelection, "preference_selection"), (.resetPassword, "reset_password"),
            (.mainLogin, "login"),
        ]
    )
    func auth(route: AuthRoute, name: String) {
        #expect(route.screenName == name)
    }

    @Test(
        "탭",
        arguments: [(Tab.home, "home"), (.ranking, "ranking"), (.research, "explore"), (.myInfo, "my_info")]
    )
    func tab(tab: Tab, name: String) {
        #expect(tab.screenName == name)
    }
}
