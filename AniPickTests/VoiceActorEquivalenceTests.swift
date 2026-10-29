//
//  VoiceActorEquivalenceTests.swift
//  AniPickTests
//
//  이관한 성우 상세가 레거시와 같은 모양인지 픽셀로 비교한다 (R Detail 3).
//  레거시는 만들 때 운영 서버에 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import DetailClientInterface
import DetailClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import DetailFeature

@MainActor
@Suite("성우 상세 ↔ 레거시", .serialized)
struct VoiceActorEquivalenceTests {
    struct Setup: Sendable {
        var name = "카지 유키"
        var liked = false
        var count = 40
        var works = 5
    }

    private func legacy(_ setup: Setup) -> some View {
        let viewModel = VoiceActorViewModel(navigationManager: NavigationManager(), animeId: 999_999)
        viewModel.actorName = setup.name
        viewModel.isLiked = setup.liked
        viewModel.workCount = setup.count
        viewModel.workList = (0..<setup.works).map {
            AniPick.PersonWork(
                animeId: $0, animeTitle: "애니 \($0)", characterId: $0, characterName: "배역 \($0)",
                characterImageUrl: nil)
        }
        return AniPick.VoiceActorDetailView(viewModel: viewModel)
    }

    private func new(_ setup: Setup) -> some View {
        var state = VoiceActorReducer.State(personId: 999_999)
        state.didStart = true
        state.name = setup.name
        state.isLiked = setup.liked
        state.workCount = setup.count
        state.works = (0..<setup.works).map {
            DetailClientInterface.PersonWork(
                animeId: $0, animeTitle: "애니 \($0)", characterId: $0, characterName: "배역 \($0)",
                characterImageUrl: nil)
        }
        return DetailFeature.VoiceActorView(
            state: state,
            reducer: VoiceActorReducer(
                detailClient: MockDetailClient(), navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test(
        "성우 상세(좋아요 전·후, 배역 없음)가 같다",
        arguments: [Setup(), Setup(liked: true), Setup(count: 0, works: 0)])
    func screen(setup: Setup) throws {
        #expect(try hostedSnapshot(legacy(setup)) == hostedSnapshot(new(setup)))
    }

    @Test("통제: 좋아요 상태가 다르면 픽셀이 다르다")
    func detectsLike() throws {
        #expect(try hostedSnapshot(legacy(Setup(liked: true))) != hostedSnapshot(new(Setup(liked: false))))
    }
}
