//
//  HomeSearchEquivalenceTests.swift
//  AniPickTests
//
//  이관한 홈 검색이 레거시와 같은 모양인지 픽셀로 비교한다 (R Home 4).
//  레거시는 보일 때 운영 서버에 인기 작품을 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//  레거시 하위 탭(selectedTab)은 View의 private @State라 결과 탭 화면은 비교하지 못한다. 첫 화면만 비교한다.
//  두 화면 모두 보일 때 저장소에서 최근 검색어를 다시 읽으므로, 검색어는 저장소(레거시 UserDefaults·Mock)에 넣는다.
//

import FeatureTestSupport
import HomeClientInterface
import HomeClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import HomeFeature

@MainActor
@Suite("홈 검색 ↔ 레거시", .serialized)
struct HomeSearchEquivalenceTests {
    struct Setup: Sendable {
        var text = ""
        var keywords: [String] = []
        var popular = Array(1...5)
    }

    private func legacy(_ setup: Setup) -> some View {
        UserDefaultsManager.shared.setHomeRecentKeywordList(setup.keywords)
        let viewModel = HomeSearchViewModel(
            usecase: SearchUsecase(searchRepository: SearchRepository(apiService: SearchAPIService())),
            navigationManager: NavigationManager())
        viewModel.searchText = setup.text
        viewModel.initAnimeList = setup.popular.map {
            Anime(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, releaseDate: nil)
        }
        return AniPick.HomeSearchView(viewModel: viewModel)
    }

    private func new(_ setup: Setup) -> some View {
        var state = HomeSearchReducer.State()
        state.searchText = setup.text
        state.popularAnimes = setup.popular.map { .sample($0) }
        let client = MockHomeClient(delay: .seconds(5))
        client.stubSearch(keywords: setup.keywords)
        return HomeFeature.HomeSearchView(
            state: state,
            reducer: HomeSearchReducer(
                homeClient: client,
                navigator: LegacyNavigator(navigationManager: NavigationManager()), analytics: RecordingTracker()))
    }

    @Test(
        "첫 화면(검색창·최근 검색어·인기 작품)이 같다",
        arguments: [Setup(), Setup(text: "원피스"), Setup(keywords: ["나루토", "주술회전", "원피스"]), Setup(popular: [])])
    func initial(setup: Setup) throws {
        defer { UserDefaultsManager.shared.clearHomeRecentKeyword() }
        #expect(try hostedSnapshot(legacy(setup)) == hostedSnapshot(new(setup)))
    }

    @Test("통제: 최근 검색어가 다르면 픽셀이 다르다")
    func detectsKeywords() throws {
        defer { UserDefaultsManager.shared.clearHomeRecentKeyword() }
        #expect(try hostedSnapshot(legacy(Setup(keywords: ["a"]))) != hostedSnapshot(new(Setup(keywords: ["b"]))))
    }

    @Test("통제: 최근 검색어가 있으면 없는 화면과 픽셀이 다르다 (검색어 칸이 실제로 그려진다)")
    func detectsKeywordSection() throws {
        defer { UserDefaultsManager.shared.clearHomeRecentKeyword() }
        #expect(try hostedSnapshot(legacy(Setup(keywords: ["a"]))) != hostedSnapshot(new(Setup())))
    }
}
