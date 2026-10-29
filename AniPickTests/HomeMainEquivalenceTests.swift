//
//  HomeMainEquivalenceTests.swift
//  AniPickTests
//
//  이관한 홈 탭이 레거시와 같은 모양인지 픽셀로 비교한다 (R Home 5).
//  레거시는 보일 때 운영 서버에 섹션들을 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//  두 화면 모두 보일 때 마지막으로 본 애니 id를 읽고, 0이면 비슷한 작품을 곧바로 비운다. 그래서 그 id는 저장소에 넣는다.
//  아래 섹션까지 그려지도록 창을 길게(2,600pt) 잡는다.
//

import HomeClientInterface
import HomeClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import HomeFeature

@MainActor
@Suite("홈 탭 ↔ 레거시", .serialized)
struct HomeMainEquivalenceTests {
    struct Setup: Sendable {
        var lastVisited = 0
        var reference: String?
        var recommendations = Array(1...4)
        var reviews = 2
    }

    private static let size = CGSize(width: 393, height: 2600)

    private func animes(_ ids: [Int]) -> [Anime] {
        return ids.map { Anime(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, releaseDate: nil) }
    }

    private func legacy(_ setup: Setup) -> some View {
        UserDefaults.standard.set(setup.lastVisited, forKey: "lastVisitedAnime")
        let viewModel = HomeViewModel(
            usecase: HomeUsecase(repo: HomeRepository(apiService: HomeAPIService())),
            navigationManager: NavigationManager())
        viewModel.trendingAnimes = (1...4).map {
            TrendingAnimes(animeId: $0, title: "인기 \($0)", coverImageUrl: nil, rank: $0)
        }
        viewModel.recommendationAnimes = animes(setup.recommendations)
        viewModel.referenceAnimeTitle = setup.reference
        viewModel.weekdayNewAnimes = animes([7, 8])
        viewModel.recentReviews = (1...setup.reviews).map {
            Review(
                reviewId: $0, animeId: 1, animeTitle: "애니 \($0)", reviewContent: "리뷰 내용 \($0)", nickname: "닉네임",
                createdAt: "2026-10-30T10:00:00")
        }
        viewModel.upcomingAnimes = animes([10, 11])
        viewModel.seasonString = 1
        viewModel.seasonYearString = 2027
        viewModel.recommendationSimilarAnimes = animes([20, 21])
        viewModel.recommendationFirstTitle = "원피스"
        viewModel.comingSoonAnimes = animes([30])
        return AniPick.HomeView(viewModel: viewModel)
            .environmentObject(AppState(navigationManager: NavigationManager()))
    }

    private func new(_ setup: Setup) -> some View {
        var state = HomeMainReducer.State(selectedWeekday: .of(Date()))
        state.trending = (1...4).map { TrendingAnime(animeId: $0, title: "인기 \($0)", coverImageUrl: nil, rank: $0) }
        state.recommendations = setup.recommendations.map { .sample($0) }
        state.referenceTitle = setup.reference
        state.weekdayAnimes = [.sample(7), .sample(8)]
        state.recentReviews = (1...setup.reviews).map {
            HomeReview(
                reviewId: $0, animeTitle: "애니 \($0)", reviewContent: "리뷰 내용 \($0)", nickname: "닉네임",
                createdAt: "2026-10-30T10:00:00")
        }
        state.upcoming = [.sample(10), .sample(11)]
        state.season = 1
        state.seasonYear = 2027
        state.similar = [.sample(20), .sample(21)]
        state.similarTitle = "원피스"
        state.comingSoon = [.sample(30)]
        let lastVisited = setup.lastVisited
        return HomeFeature.HomeMainView(
            state: state,
            reducer: HomeMainReducer(
                homeClient: MockHomeClient(delay: .seconds(5)),
                navigator: LegacyNavigator(navigationManager: NavigationManager()),
                cachedNickname: { UserDefaultsManager.shared.getNickname() }, lastVisitedAnimeId: { lastVisited },
                showRanking: {}, showExplore: { _, _ in }))
    }

    @Test(
        "홈 전체(배너·인기·추천·요일·최근 리뷰·방영 예정·비슷한 작품·공개 예정)가 같다",
        arguments: [
            Setup(), Setup(lastVisited: 9), Setup(lastVisited: 9, reference: "진격의 거인"),
            Setup(recommendations: []),
        ])
    func home(setup: Setup) throws {
        defer { UserDefaults.standard.removeObject(forKey: "lastVisitedAnime") }
        #expect(try hostedSnapshot(legacy(setup), size: Self.size) == hostedSnapshot(new(setup), size: Self.size))
    }

    @Test("통제: 비슷한 작품 섹션이 있고 없으면 픽셀이 다르다 (아래 섹션까지 그려진다)")
    func detectsSimilar() throws {
        defer { UserDefaults.standard.removeObject(forKey: "lastVisitedAnime") }
        #expect(
            try hostedSnapshot(legacy(Setup(lastVisited: 9)), size: Self.size)
                != hostedSnapshot(new(Setup(lastVisited: 0)), size: Self.size))
    }

    @Test("통제: 최근 리뷰 수가 다르면 픽셀이 다르다")
    func detectsReviews() throws {
        defer { UserDefaults.standard.removeObject(forKey: "lastVisitedAnime") }
        #expect(
            try hostedSnapshot(legacy(Setup(reviews: 2)), size: Self.size)
                != hostedSnapshot(new(Setup(reviews: 1)), size: Self.size))
    }
}
