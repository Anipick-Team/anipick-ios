//
//  RecommendationListEquivalenceTests.swift
//  AniPickTests
//
//  이관한 추천 목록 두 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R Home 1).
//  레거시는 보일 때 운영 서버에 추천을 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import HomeClientInterface
import HomeClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import HomeFeature

@MainActor
@Suite("추천 목록 ↔ 레거시", .serialized)
struct RecommendationListEquivalenceTests {
    private static let ids = Array(1...7)

    private func legacyForYou(title: String?) -> some View {
        let viewModel = RecommendViewModel(navigationManager: NavigationManager(), animeId: 1, animeTitle: title)
        viewModel.recommendationAnimes = Self.ids.map {
            Anime(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, releaseDate: nil)
        }
        return AniPick.RecommendedAnimeView(viewModel: viewModel)
    }

    private func legacySimilar(reference: String) -> some View {
        let viewModel = SimilarRecommendedAnimeViewModel(navigationManager: NavigationManager(), animeId: 1)
        viewModel.recommendationAnimes = Self.ids.map {
            Anime(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, releaseDate: nil)
        }
        viewModel.recommendationTitle = reference
        return AniPick.SimilarRecommendedAnimeView(viewModel: viewModel)
    }

    private func new(_ kind: RecommendationListReducer.Kind, nickname: String, reference: String = "", ids: [Int] = ids)
        -> some View
    {
        var state = RecommendationListReducer.State(kind: kind, nickname: nickname)
        state.items = ids.map { .sample($0) }
        state.referenceTitle = reference
        return RecommendationListView(
            state: state,
            reducer: RecommendationListReducer(
                homeClient: MockHomeClient(delay: .seconds(5)),
                navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test("취향 추천(제목 있음·없음)이 같다", arguments: ["진격의 거인", nil] as [String?])
    func forYou(title: String?) throws {
        let nickname = UserDefaultsManager.shared.getNickname()
        #expect(try hostedSnapshot(legacyForYou(title: title)) == hostedSnapshot(new(.forYou(animeTitle: title), nickname: nickname)))
    }

    @Test("비슷한 작품이 같다")
    func similar() throws {
        #expect(
            try hostedSnapshot(legacySimilar(reference: "원피스"))
                == hostedSnapshot(new(.similar(animeId: 1), nickname: "", reference: "원피스")))
    }

    @Test("통제: 목록 개수가 다르면 픽셀이 다르다")
    func detectsItems() throws {
        #expect(
            try hostedSnapshot(legacySimilar(reference: "원피스"))
                != hostedSnapshot(new(.similar(animeId: 1), nickname: "", reference: "원피스", ids: Array(1...6))))
    }

    @Test("통제: 기준 제목이 다르면 픽셀이 다르다")
    func detectsReference() throws {
        #expect(
            try hostedSnapshot(legacySimilar(reference: "원피스"))
                != hostedSnapshot(new(.similar(animeId: 1), nickname: "", reference: "나루토")))
    }
}
