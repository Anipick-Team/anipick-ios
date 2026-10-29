//
//  AnimeListEquivalenceTests.swift
//  AniPickTests
//
//  이관한 관련 작품·함께 볼만한 작품이 레거시와 같은 모양인지 픽셀로 비교한다 (R Detail 1).
//  레거시는 보일 때 운영 서버에 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import DetailClientInterface
import DetailClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import DetailFeature

@MainActor
@Suite("관련 작품·함께 볼만한 작품 ↔ 레거시", .serialized)
struct AnimeListEquivalenceTests {
    private func legacySeries(title: String, ids: [Int], count: Int) -> some View {
        let viewModel = SeriesDetailViewModel(navigationManager: NavigationManager(), animeId: 1, animeTitle: title)
        viewModel.animeList = ids.map { SeriesAnime(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, airDate: nil) }
        viewModel.count = count
        return AniPick.SeriesDetailView(viewModel: viewModel)
    }

    private func legacyRecommended(title: String, ids: [Int]) -> some View {
        let viewModel = RecommendedViewModel(navigationManager: NavigationManager(), animeId: 1, animeTitle: title)
        viewModel.recommendedAnimeList = ids.map {
            Anime(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, releaseDate: nil)
        }
        return AniPick.RecommendedView(viewModel: viewModel)
    }

    private func new(_ kind: AnimeListReducer.Kind, title: String, ids: [Int], count: Int = 0) -> some View {
        var state = AnimeListReducer.State(kind: kind, animeId: 1, animeTitle: title)
        state.items = ids.map { .sample($0) }
        state.count = count
        return DetailFeature.AnimeListView(
            state: state,
            reducer: AnimeListReducer(
                detailClient: MockDetailClient(delay: .seconds(5)),
                navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test("관련 작품(목록·빈 목록)이 같다", arguments: [(Array(1...7), 12), ([], 0)] as [([Int], Int)])
    func series(ids: [Int], count: Int) throws {
        #expect(
            try hostedSnapshot(legacySeries(title: "원피스", ids: ids, count: count))
                == hostedSnapshot(new(.series, title: "원피스", ids: ids, count: count)))
    }

    @Test("함께 볼만한 작품(목록·빈 목록)이 같다", arguments: [Array(1...5), []])
    func recommended(ids: [Int]) throws {
        #expect(
            try hostedSnapshot(legacyRecommended(title: "진격의 거인", ids: ids))
                == hostedSnapshot(new(.recommendations, title: "진격의 거인", ids: ids)))
    }

    @Test("통제: 개수가 다르면 픽셀이 다르다")
    func detectsCount() throws {
        #expect(
            try hostedSnapshot(legacySeries(title: "a", ids: [1], count: 3))
                != hostedSnapshot(new(.series, title: "a", ids: [1], count: 4)))
    }

    @Test("통제: 제목이 다르면 픽셀이 다르다")
    func detectsTitle() throws {
        #expect(
            try hostedSnapshot(legacyRecommended(title: "a", ids: [1]))
                != hostedSnapshot(new(.recommendations, title: "b", ids: [1])))
    }
}
