//
//  CommunityBoardsEquivalenceTests.swift
//  AniPickTests
//
//  이관한 탐색 커뮤니티 목록이 레거시와 같은 모양인지 픽셀로 비교한다 (R Explore 1).
//  레거시 `ExploreCommunityView`는 ViewModel을 안에서 만들어 목록을 넣을 수 없다 — 처음 화면만 비교하고,
//  목록 칸은 새 화면끼리 상태를 바꿔 그려 통제한다.
//

import CommunityClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import ExploreFeature

@MainActor
@Suite("탐색 커뮤니티 ↔ 레거시", .serialized)
struct CommunityBoardsEquivalenceTests {
    private func new(_ state: CommunityBoardsReducer.State = .init()) -> some View {
        return CommunityBoardsView(
            state: state,
            reducer: CommunityBoardsReducer(
                communityClient: MockCommunityClient(delay: .seconds(10)),
                navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test("처음 화면(검색창·정렬·빈 안내)이 같다")
    func initial() throws {
        #expect(
            try hostedSnapshot(ExploreCommunityView().environmentObject(NavigationManager()))
                == hostedSnapshot(new()))
    }

    @Test("통제: 정렬 문구가 다르면 픽셀이 다르다")
    func detectsSort() throws {
        var state = CommunityBoardsReducer.State()
        state.sortTitle = "최신순"

        #expect(
            try hostedSnapshot(ExploreCommunityView().environmentObject(NavigationManager()))
                != hostedSnapshot(new(state)))
    }
}
