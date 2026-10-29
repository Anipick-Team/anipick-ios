//
//  ExploreEquivalenceTests.swift
//  AniPickTests
//
//  이관한 탐색 탭(작품 탐색)이 레거시와 같은 모양인지 픽셀로 비교한다 (R Explore 2).
//  레거시는 보일 때 실제 서버에 다음 페이지를 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import ExploreClientInterface
import ExploreClientTesting
import MetadataClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import ExploreFeature

@MainActor
@Suite("탐색 탭 ↔ 레거시", .serialized)
struct ExploreEquivalenceTests {
    struct Setup: Sendable {
        var ids = [1, 2, 3, 4, 5]
        var tags: [(ExploreFilterTab, String)] = []
        var rating = false
        var sortMenu = false
    }

    private func legacy(_ setup: Setup) -> some View {
        let viewModel = ExploreViewModel(
            usecase: ExploreUsecase(exploreRepository: ExploreRepository(apiService: ExploreAPIService())),
            navigationManager: NavigationManager())
        viewModel.exploreItems = setup.ids.map {
            Anime(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, releaseDate: nil)
        }
        viewModel.selectedTagList = setup.tags.map { ExploreSelectedTag(category: $0.0, value: $0.1) }
        viewModel.selectedCategory = setup.rating ? .rating : .popularity
        viewModel.isShowSortOptionView = setup.sortMenu
        return AniPick.ExploreView(viewModel: viewModel)
            .environmentObject(AppState(navigationManager: NavigationManager()))
            .environmentObject(NavigationManager())
    }

    private func new(_ setup: Setup) -> some View {
        var state = ExploreReducer.State(genres: [], years: [], types: [])
        state.items = setup.ids.map { .sample($0) }
        state.tags = setup.tags.map {
            ExploreReducer.Tag(category: ExploreReducer.FilterTab(rawValue: $0.0.rawValue)!, value: $0.1)
        }
        state.sort = setup.rating ? .rating : .popularity
        state.isSortMenuPresented = setup.sortMenu
        let reducer = ExploreReducer(
            exploreClient: MockExploreClient(), metadataClient: MockMetadataClient(),
            navigator: LegacyNavigator(navigationManager: NavigationManager()),
            consumePendingFilter: { nil })
        return ExploreFeature.ExploreView(
            state: state, reducer: reducer, pendingFilterUpdates: { AsyncStream { $0.finish() } }
        ) {
            EmptyView()
        }
    }

    @Test(
        "목록·조건 칩·정렬 표시가 같다",
        arguments: [
            Setup(), Setup(tags: [(.season, "3"), (.yearQuarter, "2025"), (.genre, "SF"), (.type, "TV")]),
            Setup(tags: [(.season, "전체 분기")], rating: true), Setup(ids: []),
        ]
    )
    func states(setup: Setup) throws {
        #expect(try hostedSnapshot(legacy(setup)) == hostedSnapshot(new(setup)))
    }

    @Test("정렬 메뉴를 연 화면이 같다")
    func sortMenu() throws {
        #expect(try hostedSnapshot(legacy(Setup(sortMenu: true))) == hostedSnapshot(new(Setup(sortMenu: true))))
    }

    @Test("통제: 조건 칩이 다르면 픽셀이 다르다")
    func detectsTags() throws {
        #expect(
            try hostedSnapshot(legacy(Setup(tags: [(.type, "TV")])))
                != hostedSnapshot(new(Setup(tags: [(.type, "OVA")]))))
    }

    @Test("통제: 정렬 메뉴가 열리면 픽셀이 다르다")
    func detectsSortMenu() throws {
        #expect(try hostedSnapshot(legacy(Setup(sortMenu: true))) != hostedSnapshot(new(Setup())))
    }
}
