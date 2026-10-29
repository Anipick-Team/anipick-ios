//
//  ProducerCastEquivalenceTests.swift
//  AniPickTests
//
//  이관한 제작사 상세·캐릭터/성우진이 레거시와 같은 모양인지 픽셀로 비교한다 (R Detail 2).
//  레거시는 보일 때(제작사)·만들 때(캐릭터) 운영 서버에 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import DetailClientInterface
import DetailClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import DetailFeature

@MainActor
@Suite("제작사·캐릭터/성우진 ↔ 레거시", .serialized)
struct ProducerCastEquivalenceTests {
    private static let years: [(String, [Int])] = [("2025", [1, 2, 3, 4]), ("2023", [5])]

    private func legacyProducer(name: String, years: [(String, [Int])]) -> some View {
        let viewModel = ProducerDetailViewModel(navigationManager: NavigationManager(), studioId: 1)
        viewModel.producerName = name
        viewModel.producerList = years.map { year, ids in
            (year, ids.map { AnimeWithSeasonYear(animeId: $0, title: "애니 \($0)", coverImageUrl: nil, seasonYear: year) })
        }
        return AniPick.ProducerDetailView(viewModel: viewModel)
    }

    private func newProducer(name: String, years: [(String, [Int])]) -> some View {
        var state = ProducerReducer.State(studioId: 1)
        state.studioName = name
        state.groups = years.map { year, ids in
            ProducerReducer.YearGroup(year: year, animes: ids.map { .sample($0, year: year) })
        }
        return DetailFeature.ProducerView(
            state: state,
            reducer: ProducerReducer(
                detailClient: MockDetailClient(delay: .seconds(5)),
                navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test("제작사 상세(연도 2개)가 같다")
    func producer() throws {
        #expect(
            try hostedSnapshot(legacyProducer(name: "MAPPA", years: Self.years))
                == hostedSnapshot(newProducer(name: "MAPPA", years: Self.years)))
    }

    @Test("통제: 연도 묶음이 다르면 픽셀이 다르다")
    func detectsYears() throws {
        #expect(
            try hostedSnapshot(legacyProducer(name: "MAPPA", years: Self.years))
                != hostedSnapshot(newProducer(name: "MAPPA", years: [("2025", [1, 2, 3, 4, 5])])))
    }

    private func legacyCast(_ count: Int) -> some View {
        let viewModel = PersonDetailViewModel(navigationManager: NavigationManager(), animeId: 1)
        viewModel.castList = (0..<count).map {
            CharacterAndVoiceActorInfo(
                character: AnimeCharacter(id: $0, name: "캐릭터 \($0)", imageUrl: nil),
                voiceActor: VoiceActor(id: 100 + $0, name: "성우 \($0)", imageUrl: nil), role: nil)
        }
        return AniPick.PersonDetailView(viewModel: viewModel)
    }

    private func newCast(_ count: Int) -> some View {
        var state = CastReducer.State(animeId: 1)
        state.didStart = true
        state.cast = (0..<count).map {
            CastMember(
                character: CastPerson(id: $0, name: "캐릭터 \($0)", imageUrl: nil),
                voiceActor: CastPerson(id: 100 + $0, name: "성우 \($0)", imageUrl: nil))
        }
        return DetailFeature.CastView(
            state: state,
            reducer: CastReducer(
                detailClient: MockDetailClient(), navigator: LegacyNavigator(navigationManager: NavigationManager())))
    }

    @Test("캐릭터/성우진(5명·0명)이 같다", arguments: [5, 0])
    func cast(count: Int) throws {
        #expect(try hostedSnapshot(legacyCast(count)) == hostedSnapshot(newCast(count)))
    }

    @Test("통제: 인원이 다르면 픽셀이 다르다")
    func detectsCast() throws {
        #expect(try hostedSnapshot(legacyCast(3)) != hostedSnapshot(newCast(2)))
    }
}
