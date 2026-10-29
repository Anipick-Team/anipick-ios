//
//  RankingEquivalenceTests.swift
//  AniPickTests
//
//  이관한 랭킹 탭이 레거시와 같은 모양인지 픽셀로 비교한다 (R Ranking 1).
//  목록은 ScrollView라 창에 올려 그린다. 레거시가 다음 페이지를 실제 서버에 요청하지 않도록 양쪽 모두 "받는 중"으로 둔다.
//

import FeatureTestSupport
import MetadataClientLive
import Navigation
import RankingClientInterface
import RankingClientTesting
import SwiftUI
import Testing

@testable import AniPick
@testable import RankingFeature

@MainActor
@Suite("랭킹 탭 ↔ 레거시", .serialized)
struct RankingEquivalenceTests {
    struct Item: Sendable {
        let id: Int
        let rank: Int
        let trend: String?
        let change: String?
        let genres: [String]
    }

    private static let items = [
        Item(id: 11, rank: 1, trend: "up", change: "3", genres: ["액션"]),
        Item(id: 12, rank: 2, trend: "down", change: "-12", genres: ["판타지", "코미디"]),
        Item(id: 13, rank: 3, trend: "same", change: "0", genres: ["로맨스", "드라마", "일상", "SF"]),
        Item(id: 14, rank: 4, trend: nil, change: nil, genres: []),
    ]

    private func legacy(
        items: [Item],
        filter: RankingFilter,
        genre: String = "장르",
        year: String = "",
        season: String = ""
    ) -> some View {
        let viewModel = RankingViewModel(navigationManager: NavigationManager())
        viewModel.rankingAnimeList = items.map {
            AniPick.RankedAnime(
                animeId: $0.id, title: "애니 \($0.id)", coverImageUrl: nil, rank: $0.rank,
                change: $0.change, trend: $0.trend, genres: $0.genres, popularity: nil, trending: nil)
        }
        viewModel.isSelectedFilter = filter
        viewModel.selectedGenre = genre
        viewModel.selectedYear = year
        viewModel.selectedSeason = season
        viewModel.isLoadingPage = true
        return AniPick.RankingView(viewModel: viewModel)
    }

    private func new(
        items: [Item],
        filter: RankingReducer.Filter,
        genre: String = "장르",
        year: String = "",
        season: String = ""
    ) -> some View {
        var state = RankingReducer.State(genres: [])
        state.items = items.map {
            RankingClientInterface.RankedAnime(
                animeId: $0.id, title: "애니 \($0.id)", coverImageUrl: nil, rank: $0.rank,
                change: $0.change, trend: $0.trend, genres: $0.genres)
        }
        state.filter = filter
        state.selectedGenre = genre
        state.selectedYear = year
        state.selectedSeason = season
        state.isLoadingPage = true
        let reducer = RankingReducer(
            rankingClient: MockRankingClient([]),
            metadataClient: LiveMetadataClient(),
            navigator: LegacyNavigator(navigationManager: NavigationManager())
        )
        return RankingFeature.RankingView(state: state, reducer: reducer)
    }

    @Test("실시간 목록(순위 변화 위·아래·같음, 장르 0~4개)이 같다")
    func realTime() throws {
        #expect(
            try hostedSnapshot(legacy(items: Self.items, filter: .realTime))
                == hostedSnapshot(new(items: Self.items, filter: .realTime)))
    }

    @Test("역대 + 장르 선택(순위 변화 표시 없음)이 같다")
    func allTimeWithGenre() throws {
        #expect(
            try hostedSnapshot(legacy(items: Self.items, filter: .history, genre: "코미디"))
                == hostedSnapshot(new(items: Self.items, filter: .allTime, genre: "코미디")))
    }

    @Test("연도/분기 칩 문구가 같다", arguments: [("2025", "3"), ("2024", ""), ("", "")])
    func yearSeason(year: String, season: String) throws {
        #expect(
            try hostedSnapshot(
                legacy(items: Self.items, filter: .yearQuater, year: year, season: season))
                == hostedSnapshot(
                    new(items: Self.items, filter: .yearSeason, year: year, season: season)))
    }

    @Test("통제: 순위가 다르면 픽셀이 다르다")
    func detectsRank() throws {
        var changed = Self.items
        changed[0] = Item(id: 11, rank: 9, trend: "up", change: "3", genres: ["액션"])

        #expect(
            try hostedSnapshot(legacy(items: Self.items, filter: .realTime))
                != hostedSnapshot(new(items: changed, filter: .realTime)))
    }

    @Test("통제: 순위 변화 화살표가 다르면 픽셀이 다르다")
    func detectsTrend() throws {
        var changed = Self.items
        changed[0] = Item(id: 11, rank: 1, trend: "down", change: "3", genres: ["액션"])

        #expect(
            try hostedSnapshot(legacy(items: Self.items, filter: .realTime))
                != hostedSnapshot(new(items: changed, filter: .realTime)))
    }
}
