//
//  PreferenceEquivalenceTests.swift
//  AniPickTests
//
//  이관한 취향 선택 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R Auth 4).
//  레거시는 보일 때 메타데이터와 (1초 뒤) 목록을 실제 서버에 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import ExploreClientInterface
import ExploreClientTesting
import FeatureTestSupport
import MetadataClientTesting
import ReviewClientTesting
import SwiftUI
import Testing

@testable import AniPick
@testable import AuthFeature

@MainActor
@Suite("취향 선택 ↔ 레거시", .serialized)
struct PreferenceEquivalenceTests {
    struct Setup: Sendable {
        var ids = [1, 2, 3]
        var rated: [Int: Double] = [:]
        var opened: Set<Int> = []
        var year = ""
        var quarter = ""
        var genre = ""
    }

    private func legacy(_ setup: Setup) -> some View {
        let viewModel = PreferenceSelectionViewModel(navigationManager: NavigationManager())
        viewModel.animeList = setup.ids.map {
            AnimePreference(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, genres: ["액션", "SF"])
        }
        viewModel.storedRatedAnimeList = setup.rated.sorted { $0.key < $1.key }.map {
            AuthAnimeRatingRequest(animeId: $0.key, rating: $0.value)
        }
        viewModel.selectedAnimeList = setup.opened
        viewModel.selectedYear = setup.year
        viewModel.selectedQuarter = setup.quarter
        viewModel.selectedGenre = setup.genre
        return AniPick.PreferenceSelectionView(viewModel: viewModel)
    }

    private func new(_ setup: Setup) -> some View {
        var state = PreferenceReducer.State(genres: [], seasonYears: [])
        state.animes = setup.ids.map { .sample($0) }
        state.ratings = setup.rated.sorted { $0.key < $1.key }.map { .init(animeId: $0.key, rating: $0.value) }
        state.openedRatingIds = setup.opened
        state.selectedYear = setup.year
        state.selectedQuarter = setup.quarter
        state.selectedGenre = setup.genre
        let reducer = PreferenceReducer(
            exploreClient: MockExploreClient(), reviewClient: MockReviewClient(),
            metadataClient: MockMetadataClient(), analytics: RecordingTracker(), onLoginCompleted: {},
            firstLoadDelay: .seconds(60))
        return PreferenceView(state: state, reducer: reducer)
    }

    @Test(
        "목록·평가·열린 별점 줄·필터 칩이 같다",
        arguments: [
            Setup(), Setup(rated: [2: 3]), Setup(rated: [1: 4.5, 3: 0], opened: [2]),
            Setup(year: "2025", quarter: "3", genre: "SF"), Setup(ids: []),
        ]
    )
    func states(setup: Setup) throws {
        #expect(try hostedSnapshot(legacy(setup)) == hostedSnapshot(new(setup)))
    }

    @Test("통제: 평가한 별점이 다르면 픽셀이 다르다")
    func detectsRating() throws {
        #expect(
            try hostedSnapshot(legacy(Setup(rated: [1: 4.5])))
                != hostedSnapshot(new(Setup(rated: [1: 3.5]))))
    }
}
