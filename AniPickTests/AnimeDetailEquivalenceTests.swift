//
//  AnimeDetailEquivalenceTests.swift
//  AniPickTests
//
//  이관한 애니 상세(작품 정보 탭)가 레거시와 같은 모양인지 픽셀로 비교한다 (R Detail 4).
//  레거시는 만들 때 운영 서버에 상세·리뷰 등 7개를 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//  레거시는 보일 때 마지막으로 본 애니 id를 저장하므로 테스트 뒤 지운다.
//  긴 창(2,200pt)은 아래 섹션까지, 기본 창은 위쪽(배너·탭)을 본다. 긴 창에서는 위쪽이 잘려 그려지기 때문이다.
//

import CommunityClientTesting
import DetailClientInterface
import DetailClientTesting
import FeatureTestSupport
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import DetailFeature

@MainActor
@Suite("애니 상세 ↔ 레거시", .serialized)
struct AnimeDetailEquivalenceTests {
    struct Setup: Sendable {
        var liked = false
        var watch = ""
        var cast = 3
        var series = 2
        var recommendations = 2
        var episode: Int? = 24
        var studios = ["MAPPA", "Studio Bones"]
    }

    private static let size = CGSize(width: 393, height: 2200)

    private func legacy(_ setup: Setup) -> some View {
        let viewModel = AnimationInfoViewModel(animeId: 999_999, navigationManager: NavigationManager())
        viewModel.animeDetailInfo = AnimeDetail(
            animeId: 999_999, title: "원피스", coverImageUrl: nil, bannerImageUrl: nil, description: "해적왕을 꿈꾸는 소년의 모험",
            averageRating: "4.5", isLiked: setup.liked, watchStatus: nil, type: "TVA", reviewCount: 12,
            genres: [AniPick.Genre(id: 1, name: "액션"), AniPick.Genre(id: 2, name: "모험")], episode: setup.episode,
            airDate: "2025년 3분기", status: "방영 중", age: "15세",
            studios: setup.studios.enumerated().map { Studio(studioId: $0.offset, name: $0.element) })
        viewModel.averageRating = "4.5"
        viewModel.reviewCount = 12
        viewModel.isActiveLike = setup.liked
        viewModel.selectedAnimationStatusTab = AnimationWatchStatus.fromStatus(setup.watch) ?? .empty
        viewModel.characterInfoList = (0..<setup.cast).map {
            CastPair(
                character: AnimeCharacter(id: $0, name: "캐릭터 \($0)", imageUrl: nil),
                voiceActor: VoiceActor(id: $0, name: "성우 \($0)", imageUrl: nil), role: nil)
        }
        viewModel.seriesInfoList = (0..<setup.series).map {
            SeriesAnime(animeId: $0, title: "관련 \($0)", coverImageUrl: nil, airDate: nil)
        }
        viewModel.recommendAnimeList = (0..<setup.recommendations).map {
            Anime(animeId: $0, title: "추천 \($0)", coverImageUrl: nil, releaseDate: nil)
        }
        return AniPick.AnimationInfoView(viewModel: viewModel)
    }

    private func new(_ setup: Setup) -> some View {
        var state = AnimeDetailReducer.State(animeId: 999_999)
        state.didStart = true
        state.info = AnimeInfo(
            animeId: 999_999, title: "원피스", coverImageUrl: nil, bannerImageUrl: nil, description: "해적왕을 꿈꾸는 소년의 모험",
            averageRating: "4.5", isLiked: setup.liked, watchStatus: nil, type: "TVA", reviewCount: 12,
            genres: ["액션", "모험"], episode: setup.episode, airDate: "2025년 3분기", status: "방영 중", age: "15세",
            studios: setup.studios.enumerated().map { AnimeInfo.Studio(studioId: $0.offset, name: $0.element) })
        state.averageRating = "4.5"
        state.reviewCount = 12
        state.isLiked = setup.liked
        state.watchStatus = AnimeDetailReducer.WatchStatus(status: setup.watch)
        state.cast = (0..<setup.cast).map {
            CastMember(
                character: CastPerson(id: $0, name: "캐릭터 \($0)", imageUrl: nil),
                voiceActor: CastPerson(id: $0, name: "성우 \($0)", imageUrl: nil))
        }
        state.series = (0..<setup.series).map { DetailAnime(animeId: $0, title: "관련 \($0)", coverImageUrl: nil) }
        state.recommendations = (0..<setup.recommendations).map {
            DetailAnime(animeId: $0, title: "추천 \($0)", coverImageUrl: nil)
        }
        return DetailFeature.AnimeDetailView(
            state: state,
            reducer: AnimeDetailReducer(
                detailClient: MockDetailClient(), communityClient: MockCommunityClient(),
                navigator: LegacyNavigator(navigationManager: NavigationManager()), analytics: RecordingTracker(),
                setLastVisitedAnimeId: { _ in }, shareAnime: { _, _ in }, openURL: { _ in })
        ) { _ in
            EmptyView()
        }
    }

    @Test(
        "작품 정보 탭(좋아요·시청 상태·회차 없음·섹션 숨김)이 같다",
        arguments: [
            Setup(), Setup(liked: true, watch: "WATCHING"), Setup(watch: "FINISHED", episode: nil, studios: ["A"]),
            Setup(cast: 0, series: 0, recommendations: 0),
        ])
    func info(setup: Setup) throws {
        defer { UserDefaults.standard.removeObject(forKey: "lastVisitedAnime") }
        #expect(try hostedSnapshot(legacy(setup), size: Self.size) == hostedSnapshot(new(setup), size: Self.size))
    }

    @Test(
        "위쪽(배너·제목·좋아요·평점·시청 상태·탭·정보 줄)이 기본 화면 크기에서 같다",
        arguments: [Setup(), Setup(liked: true, watch: "WATCHLIST")])
    func top(setup: Setup) throws {
        defer { UserDefaults.standard.removeObject(forKey: "lastVisitedAnime") }
        #expect(try hostedSnapshot(legacy(setup)) == hostedSnapshot(new(setup)))
    }

    @Test("통제: 시청 상태가 다르면 픽셀이 다르다")
    func detectsWatch() throws {
        defer { UserDefaults.standard.removeObject(forKey: "lastVisitedAnime") }
        #expect(
            try hostedSnapshot(legacy(Setup(watch: "WATCHING")), size: Self.size)
                != hostedSnapshot(new(Setup(watch: "FINISHED")), size: Self.size))
    }

    @Test("통제: 아래쪽 섹션(함께 볼만한 작품) 유무가 다르면 픽셀이 다르다")
    func detectsBottomSection() throws {
        defer { UserDefaults.standard.removeObject(forKey: "lastVisitedAnime") }
        #expect(
            try hostedSnapshot(legacy(Setup(recommendations: 2)), size: Self.size)
                != hostedSnapshot(new(Setup(recommendations: 0)), size: Self.size))
    }
}
