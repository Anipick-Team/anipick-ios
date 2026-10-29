//
//  MyInfoListsEquivalenceTests.swift
//  AniPickTests
//
//  이관한 마이페이지 목록 5개가 레거시와 같은 모양인지 픽셀로 비교한다 (R MyInfo 1).
//  레거시 화면은 보일 때(onAppear) 실제 서버에 다음 페이지를 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import FeatureTestSupport
import MyInfoClientInterface
import MyInfoClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import MyInfoFeature

@MainActor
@Suite("마이페이지 목록 ↔ 레거시", .serialized)
struct MyInfoListsEquivalenceTests {
    private let navigator = LegacyNavigator(navigationManager: NavigationManager())
    private let ids = [1, 2, 3, 4, 5]

    private func legacyWatch(_ status: WatchStatus, ids: [Int], count: Int) -> AnyView {
        let viewModel = MyInfoViewModel(navigationManager: NavigationManager())
        let animes = ids.map {
            ToWatchAnime(
                animeId: $0, userAnimeStatusId: nil, title: "애니 \($0)", coverImageUrl: nil,
                myRating: $0 % 2 == 0 ? 4.5 : nil)
        }
        switch status {
        case .watchList:
            viewModel.toWatchList = animes
            viewModel.toWatchListCount = count
            return AnyView(ToWatchListView(viewModel: viewModel))
        case .watching:
            viewModel.watchingList = animes
            viewModel.watchingListCount = count
            return AnyView(WatchingListView(viewModel: viewModel))
        case .finished:
            viewModel.finishedList = animes
            viewModel.finishedListCount = count
            return AnyView(FinishedWatchingListView(viewModel: viewModel))
        }
    }

    private func newWatch(_ status: WatchStatus, ids: [Int], count: Int) -> some View {
        var state = WatchListReducer.State(status: status)
        state.items = ids.map { .sample($0, rating: $0 % 2 == 0 ? 4.5 : nil) }
        state.count = count
        return WatchListView(
            state: state,
            reducer: WatchListReducer(status: status, myInfoClient: MockMyInfoClient(), navigator: navigator)
        )
    }

    @Test("볼·보는 중·다 본 애니 목록이 같다", arguments: WatchStatus.allCases)
    func watchLists(status: WatchStatus) throws {
        #expect(
            try hostedSnapshot(legacyWatch(status, ids: ids, count: 23))
                == hostedSnapshot(newWatch(status, ids: ids, count: 23)))
    }

    @Test("빈 화면이 같다", arguments: WatchStatus.allCases)
    func emptyLists(status: WatchStatus) throws {
        #expect(
            try hostedSnapshot(legacyWatch(status, ids: [], count: 0))
                == hostedSnapshot(newWatch(status, ids: [], count: 0)))
    }

    @Test("좋아요한 작품이 같다")
    func likedAnimes() throws {
        let viewModel = LikeAnimeListViewModel(navigationManager: NavigationManager())
        viewModel.animeList = ids.map {
            LikedAnime(animeId: $0, animeLikeId: nil, title: "애니 \($0)", coverImageUrl: nil)
        }
        viewModel.count = 41
        var state = LikedAnimesReducer.State()
        state.items = ids.map { .sample($0) }
        state.count = 41
        state.didLoad = true

        #expect(
            try hostedSnapshot(LikeAnimeListView(viewModel: viewModel))
                == hostedSnapshot(
                    LikedAnimesView(
                        state: state,
                        reducer: LikedAnimesReducer(myInfoClient: MockMyInfoClient(), navigator: navigator))))
    }

    @Test("좋아요한 인물이 같다")
    func likedPersons() throws {
        let viewModel = LikePersonViewModel(navigationManager: NavigationManager())
        viewModel.likedPersonList = ids.map {
            LikedRatedPerson(personId: $0, userLikedVoiceActorId: nil, name: "인물 \($0)", profileImageUrl: nil)
        }
        viewModel.likedPersonCount = 7
        var state = LikedPersonsReducer.State()
        state.items = ids.map { .sample($0) }
        state.count = 7
        state.didLoad = true

        #expect(
            try hostedSnapshot(LikePersonListView(viewModel: viewModel))
                == hostedSnapshot(
                    LikedPersonsView(
                        state: state,
                        reducer: LikedPersonsReducer(myInfoClient: MockMyInfoClient(), navigator: navigator))))
    }

    @Test("통제: 다 본 애니의 내 평가가 다르면 픽셀이 다르다")
    func detectsRating() throws {
        var state = WatchListReducer.State(status: .finished)
        state.items = ids.map { .sample($0, rating: 3.0) }
        state.count = 23
        let changed = WatchListView(
            state: state,
            reducer: WatchListReducer(status: .finished, myInfoClient: MockMyInfoClient(), navigator: navigator))

        #expect(try hostedSnapshot(legacyWatch(.finished, ids: ids, count: 23)) != hostedSnapshot(changed))
    }

    @Test("통제: 총 개수가 다르면 픽셀이 다르다")
    func detectsCount() throws {
        #expect(
            try hostedSnapshot(legacyWatch(.watchList, ids: ids, count: 23))
                != hostedSnapshot(newWatch(.watchList, ids: ids, count: 24)))
    }
}
