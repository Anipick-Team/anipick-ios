//
//  MyInfoMainEquivalenceTests.swift
//  AniPickTests
//
//  이관한 마이페이지 메인이 레거시와 같은 모양인지 픽셀로 비교한다 (R MyInfo 4).
//  프로필 이미지는 레거시 View의 private @State라 넣을 수 없다 — 양쪽 모두 기본 구름 이미지로 비교한다.
//  레거시는 보일 때 실제 서버에 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
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
@Suite("마이페이지 메인 ↔ 레거시", .serialized)
struct MyInfoMainEquivalenceTests {
    private func legacy(counts: (Int, Int, Int), animes: [Int], persons: [Int]) -> some View {
        let viewModel = MyInfoViewModel(navigationManager: NavigationManager())
        viewModel.watchListCount = counts.0
        viewModel.watchingCount = counts.1
        viewModel.finishedCount = counts.2
        viewModel.likedAnimeList = animes.map {
            LikedAnime(animeId: $0, animeLikeId: nil, title: "애니 \($0)", coverImageUrl: nil)
        }
        viewModel.likedPersonList = persons.map {
            LikedRatedPerson(personId: $0, userLikedVoiceActorId: nil, name: "인물 \($0)", profileImageUrl: nil)
        }
        return AniPick.MyInfoView(viewModel: viewModel)
    }

    private func new(counts: (Int, Int, Int), animes: [Int], persons: [Int]) -> some View {
        var state = MyInfoMainReducer.State()
        state.watchListCount = counts.0
        state.watchingCount = counts.1
        state.finishedCount = counts.2
        state.likedAnimes = animes.map { .sample($0) }
        state.likedPersons = persons.map { .sample($0) }
        return MyInfoMainView(
            state: state,
            reducer: MyInfoMainReducer(
                myInfoClient: MockMyInfoClient(),
                navigator: LegacyNavigator(navigationManager: NavigationManager()),
                openURL: { _ in })
        )
    }

    @Test("개수·좋아요한 작품·인물이 있는 화면이 같다")
    func filled() throws {
        #expect(
            try hostedSnapshot(legacy(counts: (3, 12, 140), animes: [1, 2, 3, 4], persons: [5, 6, 7]))
                == hostedSnapshot(new(counts: (3, 12, 140), animes: [1, 2, 3, 4], persons: [5, 6, 7])))
    }

    @Test("비어 있는 화면(빈 이미지 두 개)이 같다")
    func empty() throws {
        #expect(
            try hostedSnapshot(legacy(counts: (0, 0, 0), animes: [], persons: []))
                == hostedSnapshot(new(counts: (0, 0, 0), animes: [], persons: [])))
    }

    @Test("통제: 개수가 다르면 픽셀이 다르다")
    func detectsCount() throws {
        #expect(
            try hostedSnapshot(legacy(counts: (3, 12, 140), animes: [], persons: []))
                != hostedSnapshot(new(counts: (3, 12, 141), animes: [], persons: [])))
    }
}
