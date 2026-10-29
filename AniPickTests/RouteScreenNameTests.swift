//
//  RouteScreenNameTests.swift
//  AniPickTests
//
//  이관한 화면의 Route가 레거시 AppRoute와 같은 화면 조회 이름을 쓰는지 (R14)
//

import DetailInterface
import HomeInterface
import MyInfoInterface
import ReviewInterface
import SettingInterface
import Testing

@testable import AniPick

@MainActor
@Suite("Route 화면 이름 ↔ 레거시 AppRoute")
struct RouteScreenNameTests {
    @Test(
        "설정 Route",
        arguments: [
            (SettingRoute.main, AppRoute.setting), (.editNickname, .editNickname),
            (.withdrawal, .deleteAccount), (.editPassword, .editPassword), (.editEmail, .editEmail),
        ]
    )
    func setting(route: SettingRoute, legacy: AppRoute) {
        #expect(route.screenName == legacy.screenName)
    }

    @Test("리뷰 Route")
    func review() {
        let route = ReviewRoute.write(animeId: 1, rating: 3, content: "")
        let legacy = AppRoute.review(starRating: 3, animeId: 1, reviewContent: "")

        #expect(route.screenName == legacy.screenName)
    }

    @Test("아직 레거시인 상세·검색 Route")
    func legacyBacked() {
        #expect(DetailRoute.anime(id: 1).screenName == AppRoute.animeDetail(animeId: 1).screenName)
        #expect(HomeRoute.search.screenName == AppRoute.homeSearch.screenName)
    }

    @Test(
        "마이페이지 목록 Route",
        arguments: [
            (MyInfoRoute.watchList, AppRoute.myInfoInToWatchList), (.watching, .myInfoWatchingList),
            (.finished, .finishedWatchList), (.likedAnimes, .likeAnimeList), (.likedPersons, .likePersonList),
            (.ratedReviews, .ratedAnimeList),
        ]
    )
    func myInfo(route: MyInfoRoute, legacy: AppRoute) {
        #expect(route.screenName == legacy.screenName)
    }

    @Test("성우 상세 Route")
    func voiceActor() {
        #expect(
            DetailRoute.voiceActor(id: 1).screenName == AppRoute.voiceActorDetail(animeId: 1).screenName)
    }
}
