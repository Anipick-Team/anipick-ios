import Analytics
import CommunityClientInterface
import DetailClientInterface
import Foundation
import DetailInterface
import Navigation
import ReviewClientInterface
import SwiftUI

public struct DetailDependencies {
    public let detailClient: any DetailClient
    public let reviewClient: any ReviewClient
    public let communityClient: any CommunityClient
    public let navigator: any Navigator
    public let analytics: any AnalyticsTracking
    /// 마지막으로 본 애니 저장 (App: 레거시 `UserDefaultsManager.setLastVisitedAnimeId`)
    public let setLastVisitedAnimeId: @MainActor (Int) -> Void
    /// 공유 시트 (App: 문구 + Universal Link — 딥링크 경로는 App이 안다)
    public let shareAnime: @MainActor (_ animeId: Int, _ title: String) -> Void
    public let openURL: @MainActor (URL) -> Void
    /// 이미지 id를 받을 주소 (`{서버}api/image/{id}`, 인증 필요). 리뷰 작성자 프로필에 쓴다
    public let imageURL: @Sendable (Int) -> URL

    public init(
        detailClient: any DetailClient,
        reviewClient: any ReviewClient,
        communityClient: any CommunityClient,
        navigator: any Navigator,
        analytics: any AnalyticsTracking,
        setLastVisitedAnimeId: @escaping @MainActor (Int) -> Void = { _ in },
        shareAnime: @escaping @MainActor (_ animeId: Int, _ title: String) -> Void = { _, _ in },
        openURL: @escaping @MainActor (URL) -> Void = { _ in },
        imageURL: @escaping @Sendable (Int) -> URL = {
            URL(string: "https://example.invalid/api/image/\($0)")!
        }
    ) {
        self.detailClient = detailClient
        self.reviewClient = reviewClient
        self.imageURL = imageURL
        self.communityClient = communityClient
        self.navigator = navigator
        self.analytics = analytics
        self.setLastVisitedAnimeId = setLastVisitedAnimeId
        self.shareAnime = shareAnime
        self.openURL = openURL
    }
}

public struct DetailBuilder: DetailBuilding {
    private let dependencies: DetailDependencies

    public init(dependencies: DetailDependencies) {
        self.dependencies = dependencies
    }

    public func make(_ route: DetailRoute) -> AnyView {
        switch route {
        case .series(let animeId, let animeTitle):
            return makeList(.series, animeId: animeId, animeTitle: animeTitle)
        case .recommendations(let animeId, let animeTitle):
            return makeList(.recommendations, animeId: animeId, animeTitle: animeTitle)
        case .producer(let id):
            return AnyView(
                ProducerView(
                    state: ProducerReducer.State(studioId: id),
                    reducer: ProducerReducer(
                        detailClient: dependencies.detailClient, navigator: dependencies.navigator))
            )
        case .cast(let animeId):
            return AnyView(
                CastView(
                    state: CastReducer.State(animeId: animeId),
                    reducer: CastReducer(
                        detailClient: dependencies.detailClient, navigator: dependencies.navigator))
            )
        case .voiceActor(let id):
            return AnyView(
                VoiceActorView(
                    state: VoiceActorReducer.State(personId: id),
                    reducer: VoiceActorReducer(
                        detailClient: dependencies.detailClient, navigator: dependencies.navigator))
            )
        case .anime(let id):
            let reducer = AnimeDetailReducer(
                detailClient: dependencies.detailClient,
                reviewClient: dependencies.reviewClient,
                communityClient: dependencies.communityClient,
                navigator: dependencies.navigator,
                analytics: dependencies.analytics,
                setLastVisitedAnimeId: dependencies.setLastVisitedAnimeId,
                shareAnime: dependencies.shareAnime,
                openURL: dependencies.openURL
            )
            return AnyView(
                AnimeDetailView(
                    state: AnimeDetailReducer.State(animeId: id), reducer: reducer,
                    imageURL: dependencies.imageURL))
        }
    }

    private func makeList(_ kind: AnimeListReducer.Kind, animeId: Int, animeTitle: String)
        -> AnyView
    {
        let reducer = AnimeListReducer(
            detailClient: dependencies.detailClient, navigator: dependencies.navigator)
        return AnyView(
            AnimeListView(
                state: AnimeListReducer.State(kind: kind, animeId: animeId, animeTitle: animeTitle),
                reducer: reducer))
    }
}
