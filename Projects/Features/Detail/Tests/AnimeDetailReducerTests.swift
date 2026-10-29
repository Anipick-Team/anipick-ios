import ClientCore
import CommunityClientInterface
import CommunityClientTesting
import DetailClientInterface
import DetailClientTesting
import DetailInterface
import ExploreInterface
import FeatureTestSupport
import Foundation
import MVICore
import ReviewClientTesting
import Testing
import os

@testable import DetailFeature

/// 동작 목록 AD3~AD17 (notes/2026-10-30-R-detail-04-anime-info.md)과 1:1
@Suite("애니 상세 (작품 정보)", .timeLimit(.minutes(1)))
struct AnimeDetailReducerTests {
    private let navigator = RecordingNavigator()
    private let tracker = RecordingTracker()
    private let client = MockDetailClient()
    private let community = MockCommunityClient()
    private let reviews = MockReviewClient()
    private let visited = OSAllocatedUnfairLock<[Int]>(initialState: [])
    private let shared = OSAllocatedUnfairLock<[String]>(initialState: [])
    private let opened = OSAllocatedUnfairLock<[URL]>(initialState: [])

    private func makeStore(_ animeId: Int = 7) -> Store<AnimeDetailReducer> {
        return Store(
            initialState: .init(animeId: animeId),
            reducer: AnimeDetailReducer(
                detailClient: client, reviewClient: reviews, communityClient: community,
                navigator: navigator, analytics: tracker,
                setLastVisitedAnimeId: { [visited] id in visited.withLock { $0.append(id) } },
                shareAnime: { [shared] id, title in shared.withLock { $0.append("\(id) \(title)") }
                },
                openURL: { [opened] url in opened.withLock { $0.append(url) } }))
    }

    private func loaded(_ info: AnimeInfo = .sample(7)) async -> Store<AnimeDetailReducer> {
        client.stubAnime(.init(info: .success(info)))
        let store = makeStore()
        await store.send(.appeared).finish()
        return store
    }

    @Test("AD3. 보일 때마다 마지막으로 본 애니로 저장하고, 상세·관련 목록·캐스트·관련 작품·추천은 처음 한 번만 받는다")
    func loadsOnce() async {
        client.stubAnime(
            .init(
                info: .success(.sample(7)), cast: .success([.sample(1)]),
                series: .success([.sample(2)]),
                recommendations: .success([.sample(3)])))
        let store = makeStore()

        await store.send(.appeared).finish()
        await store.send(.appeared).finish()

        #expect(visited.withLock { $0 } == [7, 7])
        #expect(
            Set(client.requests)
                == [
                    .animeInfo(7), .series(animeId: 7, lastId: nil), .detailCast(7),
                    .detailSeries(7), .detailRecommendations(7),
                ])
        #expect(client.requests.count == 5)
        #expect(store.state.cast.count == 1)
        #expect(store.state.series.map(\.animeId) == [2])
        #expect(store.state.recommendations.map(\.animeId) == [3])
    }

    @Test("AD4. 상세를 받으면 평점(없으면 -)·리뷰 수·좋아요·시청 상태를 쓰고 조회 이벤트를 남긴다. 실패하면 오류만 남긴다")
    func info() async {
        let empty = AnimeInfo(
            animeId: 7, title: "T", coverImageUrl: nil, bannerImageUrl: nil, description: nil,
            averageRating: nil,
            isLiked: nil, watchStatus: "FINISHED", type: nil, reviewCount: nil, genres: nil,
            episode: nil, airDate: nil,
            status: nil, age: nil, studios: nil)
        let store = await loaded(empty)

        #expect(store.state.averageRating == "-")
        #expect(store.state.reviewCount == 0)
        #expect(!store.state.isLiked)
        #expect(store.state.watchStatus == .finished)
        #expect(
            await waitUntil {
                tracker.events.contains(.animeDetailView(animeId: 7, animeTitle: "T"))
            })

        client.stubAnime(.init(info: .failure(.offline)))
        let failed = makeStore()
        await failed.send(.appeared).finish()
        #expect(
            await waitUntil {
                tracker.nonFatals.contains { $0.breadcrumb.hasPrefix("[fetchAnimationInfo]") }
            })
        #expect(failed.state.info == nil)
    }

    @Test("AD5. 배너는 배너 주소, 없으면(공백 포함) 표지 주소, 둘 다 없으면 nil")
    func bannerURL() {
        var state = AnimeDetailReducer.State(animeId: 1)
        func info(banner: String?, cover: String?) -> AnimeInfo {
            return AnimeInfo(
                animeId: 1, title: nil, coverImageUrl: cover, bannerImageUrl: banner,
                description: nil, averageRating: nil,
                isLiked: nil, watchStatus: nil, type: nil, reviewCount: nil, genres: nil,
                episode: nil, airDate: nil,
                status: nil, age: nil, studios: nil)
        }
        state.info = info(banner: " https://b ", cover: "https://c")
        #expect(state.bannerURL?.absoluteString == "https://b")
        state.info = info(banner: "  ", cover: "https://c")
        #expect(state.bannerURL?.absoluteString == "https://c")
        state.info = info(banner: nil, cover: nil)
        #expect(state.bannerURL == nil)
    }

    @Test("AD6. 좋아요: 응답이 온 뒤 토글하고 이벤트를 남긴다. 실패하면 그대로")
    func like() async {
        let store = await loaded()

        await store.send(.likeTapped).finish()
        #expect(store.state.isLiked)
        await store.send(.likeTapped).finish()
        #expect(!store.state.isLiked)

        client.stubAnime(.init(info: .success(.sample(7)), like: .failure(.offline)))
        await store.send(.likeTapped).finish()
        #expect(!store.state.isLiked)
        #expect(
            Array(client.requests.suffix(3))
                == [
                    .animeLike(id: 7, liked: true), .animeLike(id: 7, liked: false),
                    .animeLike(id: 7, liked: true),
                ])
        #expect(
            await waitUntil { tracker.events.contains(.animeUnlike(animeId: 7, animeTitle: "원피스")) }
        )
        #expect(tracker.events.contains(.animeLike(animeId: 7, animeTitle: "원피스")))
    }

    @Test("AD7. 시청 상태: 다른 버튼은 그 상태로 바꾸고 보낸다. 같은 버튼은 비우고 지운다. 128이면 지우고 다시 보낸다")
    func watchStatus() async {
        client.stubAnime(.init(info: .success(.sample(7)), statusCodes: [128, 200]))
        let store = makeStore()

        await store.send(.watchStatusTapped(.watching)).finish()
        #expect(store.state.watchStatus == .watching)
        #expect(
            await waitUntil {
                client.requests.filter { $0 == .watchStatus(animeId: 7, status: "WATCHING") }.count
                    == 2
            })
        #expect(client.requests.contains(.deleteWatchStatus(7)))

        await store.send(.watchStatusTapped(.watching)).finish()
        #expect(store.state.watchStatus == .empty)
        #expect(client.requests.filter { $0 == .deleteWatchStatus(7) }.count == 2)
    }

    @Test("AD8. 공유: 상세가 있을 때만 App에 넘기고(제목이 없으면 애니픽) 이벤트를 남긴다")
    func share() async {
        let empty = makeStore()
        await empty.send(.shareTapped).finish()
        #expect(shared.withLock { $0 }.isEmpty)

        let store = await loaded(.sample(7, title: nil))
        await store.send(.shareTapped).finish()

        #expect(shared.withLock { $0 } == ["7 애니픽"])
        #expect(
            await waitUntil { tracker.events.contains(.animeShare(animeId: 7, animeTitle: "애니픽")) })
    }

    @Test("AD9. 커뮤니티 탭: 게시판이 있으면 그 게시판으로(값이 없으면 상세 값으로), 없으면 안내 창. 확인 중에는 다시 묻지 않는다")
    func community() async {
        let store = await loaded()
        community.stubBoard(
            .success(
                AnimeBoard(seriesId: 4, hasBoard: true, title: nil, coverImageUrl: nil, genres: []))
        )

        await store.send(.communityTapped).finish()

        #expect(
            navigator.actions
                == [
                    .push(
                        ExploreRoute.communityBoard(
                            seriesId: 4, animeTitle: "원피스", coverImageUrl: nil,
                            genreNames: ["액션", "모험"]))
                ])
        #expect(store.state.selectedTab == .info)

        community.stubBoard(
            .success(
                AnimeBoard(
                    seriesId: nil, hasBoard: false, title: nil, coverImageUrl: nil, genres: nil)))
        await store.send(.communityTapped).finish()
        #expect(store.state.isCommunityMissingPresented)
        await store.send(.communityInquiryTapped).finish()
        #expect(!store.state.isCommunityMissingPresented)
        #expect(opened.withLock { $0 } == [AnimeDetailReducer.communityInquiryURL])

        let checking = store.send(.communityTapped)
        #expect(store.state.isCheckingCommunity)
        await store.send(.communityTapped).finish()
        await checking.finish()
        #expect(community.animeBoardRequests.count == 3)
    }

    @Test("AD10. 커뮤니티 확인이 실패하면 아무것도 하지 않는다. 상세가 없으면 묻지 않는다")
    func communityFailure() async {
        let empty = makeStore()
        await empty.send(.communityTapped).finish()
        #expect(community.animeBoardRequests.isEmpty)

        let store = await loaded()
        community.stubBoard(.failure(.offline))
        await store.send(.communityTapped).finish()
        #expect(!store.state.isCommunityMissingPresented)
        #expect(!store.state.isCheckingCommunity)
        #expect(navigator.actions.isEmpty)
    }

    @Test("AD11. 탭 전환과 이미지 미리보기")
    func tabsAndPreview() async {
        let store = makeStore()

        await store.send(.tabSelected(.reviews)).finish()
        await store.send(.imageTapped(URL(string: "https://x"))).finish()
        #expect(store.state.previewImageURL?.absoluteString == "https://x")
        await store.send(.previewClosed).finish()

        #expect(store.state.selectedTab == .reviews)
        #expect(store.state.previewImageURL == nil)
    }

    @Test("AD12~AD17. 이동: 캐스트 머리·캐스트(성우)·관련 작품·함께 볼만한 작품(제목, 없으면 -)·작품·제작사(id 없으면 0)·뒤로")
    func navigation() async {
        let store = await loaded(.sample(7, title: nil))

        for intent: AnimeDetailReducer.Intent in [
            .castHeaderTapped, .castTapped(.sample(1)), .seriesHeaderTapped,
            .recommendationsHeaderTapped,
            .animeTapped(animeId: 9), .producerTapped(studioId: nil), .backTapped,
        ] {
            await store.send(intent).finish()
        }

        #expect(
            navigator.actions
                == [
                    .push(DetailRoute.cast(animeId: 7)), .push(DetailRoute.voiceActor(id: 101)),
                    .push(DetailRoute.series(animeId: 7, animeTitle: "-")),
                    .push(DetailRoute.recommendations(animeId: 7, animeTitle: "-")),
                    .push(DetailRoute.anime(id: 9)),
                    .push(DetailRoute.producer(id: 0)), .pop,
                ])
    }
}
