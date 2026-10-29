//
//  RouteScreenNameTests.swift
//  AniPickTests
//
//  이관한 화면의 Route가 레거시 AppRoute와 같은 화면 조회 이름을 쓰는지 (R14)
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
        #expect(HomeRoute.main.screenName == AppRoute.homeView.screenName)
        #expect(
            HomeRoute.recommendations(animeId: 1, animeTitle: nil).screenName
                == AppRoute.recommend2(animeId: 1, animeTitle: nil).screenName)
        #expect(HomeRoute.comingSoon.screenName == AppRoute.comingSoonDetail.screenName)
        #expect(HomeRoute.recentReviews.screenName == AppRoute.recentReview.screenName)
        #expect(HomeRoute.weekdayNewAnime(day: 1).screenName == AppRoute.weekdayNewAnime(day: 1).screenName)
        #expect(
            HomeRoute.similarRecommendations(animeId: 1).screenName
                == AppRoute.recommendView(animeId: 1).screenName)
    }

    @Test(
        "마이페이지 목록 Route",
        arguments: [
            (MyInfoRoute.main, AppRoute.myInfo), (.watchList, .myInfoInToWatchList), (.watching, .myInfoWatchingList),
            (.finished, .finishedWatchList), (.likedAnimes, .likeAnimeList), (.likedPersons, .likePersonList),
            (.ratedReviews, .ratedAnimeList), (.myContent, .myContent),
        ]
    )
    func myInfo(route: MyInfoRoute, legacy: AppRoute) {
        #expect(route.screenName == legacy.screenName)
    }

    @Test("성우 상세 Route")
    func voiceActor() {
        #expect(
            DetailRoute.voiceActor(id: 1).screenName == AppRoute.voiceActorDetail(animeId: 1).screenName)
        #expect(DetailRoute.producer(id: 1).screenName == AppRoute.producerDetail(studioId: 1).screenName)
        #expect(
            DetailRoute.cast(animeId: 1).screenName == AppRoute.characterAndVoiceActorDetail(animeId: 1).screenName)
        #expect(
            DetailRoute.series(animeId: 1, animeTitle: "").screenName
                == AppRoute.seriesDetail(animeId: 1, animeTitle: "").screenName)
        #expect(
            DetailRoute.recommendations(animeId: 1, animeTitle: "").screenName
                == AppRoute.recommend(animeId: 1, animeTitle: "").screenName)
    }

    @Test("커뮤니티 게시글 Route")
    func communityPost() {
        #expect(
            ExploreRoute.communityPost(id: 1).screenName
                == AppRoute.communityDetail(postId: 1).screenName)
        #expect(
            ExploreRoute.communityBoard(seriesId: 1, animeTitle: "", coverImageUrl: nil, genreNames: []).screenName
                == AppRoute.community(seriesId: 1, animeTitle: "", coverImageUrl: nil, genreNames: []).screenName)
        #expect(
            ExploreRoute.communityWrite(seriesId: 1, animeTitle: "").screenName
                == AppRoute.communityWrite(seriesId: 1, animeTitle: "").screenName)
        #expect(
            ExploreRoute.communityEdit(
                postId: 1, seriesId: 1, animeTitle: "", title: "", content: "", isSpoiler: false, imageIds: []
            ).screenName
                == AppRoute.communityEdit(
                    postId: 1, seriesId: 1, animeTitle: "", title: "", content: "", isSpoiler: false, imageIds: []
                ).screenName)
    }

    @Test(
        "로그인 Route",
        arguments: [
            (AuthRoute.emailLogin, AppRoute.emailLogin), (.emailSignup, .emailSignup),
            (.findPassword, .findPassword), (.loginProblem, .LoginProblem),
            (.preferenceSelection, .preferenceSelection), (.resetPassword, .resetPassword),
            (.mainLogin, .mainLoginView),
        ]
    )
    func auth(route: AuthRoute, legacy: AppRoute) {
        #expect(route.screenName == legacy.screenName)
    }
}
