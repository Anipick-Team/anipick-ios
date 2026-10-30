//
//  AppDIContainer.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//
import Combine
import DesignSystem
import DetailClientLive
import DetailFeature
import DetailInterface
import HomeFeature
import HomeClientLive
import HomeInterface
import SwiftUI
import AuthClientLive
import AuthFeature
import AuthInterface
import CommunityClientLive
import ExploreFeature
import ExploreInterface
import ExploreClientLive
import MetadataClientLive
import MyInfoClientLive
import MyInfoFeature
import MyInfoInterface
import Navigation
import RankingClientLive
import RankingFeature
import RankingInterface
import ReviewClientLive
import ReviewFeature
import ReviewInterface
import SettingFeature
import SettingInterface
import Session
import UserClientLive

@MainActor
struct AppDIContainer {
    /// 탭별 스택과 로그인 상태. Feature의 Navigator이기도 하다 (Phase 4-2)
    static let router = AppRouter(isLoggedIn: !UserDefaultsManager.shared.getAccessToken().isEmpty)
    static let appState = AppState(router: router)
    static let sessionState = SessionState(router: router)
    static var navigator: any Navigator { router }

    // MARK: - Feature 빌더
    static let settingBuilder: any SettingBuilding = makeSettingBuilder()

    private static func makeSettingBuilder() -> any SettingBuilding {
        return SettingBuilder(
            dependencies: SettingDependencies(
                userClient: LiveUserClient(
                    client: AppSession.httpClient,
                    onWithdrawn: { await AppSession.shared.signOut(.withdrawal) }
                ),
                authClient: liveAuthClient,
                navigator: navigator,
                openURL: { UIApplication.shared.open($0) },
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            )
        )
    }

    static let authBuilder: any AuthBuilding = AuthBuilder(
        dependencies: AuthDependencies(
            authClient: liveAuthClient,
            exploreClient: LiveExploreClient(client: AppSession.httpClient),
            reviewClient: LiveReviewClient(client: AppSession.httpClient),
            metadataClient: LiveMetadataClient(client: AppSession.httpClient),
            navigator: navigator,
            analytics: AppAnalytics.tracker,
            onLoginCompleted: { router.completeLogin() },
            openURL: { UIApplication.shared.open($0) }
        )
    )

    /// 로그인·로그아웃. 로그인 토큰은 AuthSession에 저장한다
    static let liveAuthClient = LiveAuthClient(
        client: AppSession.httpClient,
        accessToken: { await AppSession.shared.accessToken() },
        // 레거시 순서: 사용자 정보 정리 → 로그아웃 (EditEmailViewModel.swift:58-62)
        onLoggedOut: {
            UserDefaultsManager.shared.logoutAllClearInfo()
            await AppSession.shared.signOut(.userLogout)
        },
        storeTokens: { access, refresh in
            await AppSession.shared.store(TokenPair(accessToken: access, refreshToken: refresh))
        },
        // TODO: 보안처리 필요 (레거시 AppDelegate와 같은 키)
        kakaoAppKey: "0342f72c46d8653e8a501fe5704a540c"
    )

    static let exploreBuilder: any ExploreBuilding = makeExploreBuilder()

    private static func makeExploreBuilder() -> any ExploreBuilding {
        return ExploreBuilder(
            dependencies: ExploreDependencies(
                communityClient: LiveCommunityClient(
                    client: AppSession.httpClient, imageBaseURL: URL(string: NetworkManager.baseUrl)!),
                exploreClient: LiveExploreClient(client: AppSession.httpClient),
                metadataClient: LiveMetadataClient(client: AppSession.httpClient),
                navigator: navigator,
                // 홈 "곧 방영"이 넘긴 연도·분기 (레거시 AppState)
                consumePendingFilter: {
                    appState.consumeExploreFilter().map { PendingExploreFilter(year: $0.year, season: $0.season) }
                },
                pendingFilterUpdates: {
                    AsyncStream { continuation in
                        let task = Task {
                            for await _ in appState.$pendingExploreFilter.dropFirst().values {
                                continuation.yield()
                            }
                            continuation.finish()
                        }
                        continuation.onTermination = { _ in task.cancel() }
                    }
                },
                // 레거시 CommunityDetailViewModel.makeShareItems와 같은 링크
                sharePost: { postId in
                    ShareSheet.present(items: DeepLink.communityPost(id: postId).universalLink.map { [$0] } ?? [])
                }
            )
        )
    }

    static let myInfoBuilder: any MyInfoBuilding = MyInfoBuilder(
        dependencies: MyInfoDependencies(
            myInfoClient: LiveMyInfoClient(
                client: AppSession.httpClient,
                imageBaseURL: URL(string: NetworkManager.baseUrl)!
            ),
            reviewClient: LiveReviewClient(client: AppSession.httpClient),
            navigator: navigator,
            ratedReviewsReloadNotification: .reloadRatedAnime,
            openURL: { UIApplication.shared.open($0) }
        )
    )

    /// 인증이 필요한 이미지(커뮤니티 첨부)에 토큰을 붙여 받는다 (레거시 CommunityRemoteImage)
    static let protectedImageLoader = RemoteImageLoader { request in
        var request = request
        if let token = await AppSession.shared.accessToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    static let detailBuilder: any DetailBuilding = DetailBuilder(
        dependencies: DetailDependencies(
            detailClient: LiveDetailClient(client: AppSession.httpClient),
            reviewClient: LiveReviewClient(client: AppSession.httpClient),
            communityClient: LiveCommunityClient(
                client: AppSession.httpClient, imageBaseURL: URL(string: NetworkManager.baseUrl)!),
            navigator: navigator,
            analytics: AppAnalytics.tracker,
            setLastVisitedAnimeId: { UserDefaultsManager.shared.setLastVisitedAnimeId(animeId: $0) },
            // 레거시 AnimationInfoViewModel.makeShareItems와 같은 문구·링크
            shareAnime: { animeId, title in
                let text = "애니픽에서 '\(title)'을 확인해보세요!"
                ShareSheet.present(items: DeepLink.anime(id: animeId).universalLink.map { [text, $0] } ?? [text])
            },
            openURL: { UIApplication.shared.open($0) },
            imageURL: { URL(string: "\(NetworkManager.baseUrl)api/image/\($0)")! }
        )
    )

    static let homeBuilder: any HomeBuilding = HomeBuilder(
        dependencies: HomeDependencies(
            homeClient: LiveHomeClient(client: AppSession.httpClient),
            reviewClient: LiveReviewClient(client: AppSession.httpClient),
            navigator: navigator,
            analytics: AppAnalytics.tracker,
            cachedNickname: { UserDefaultsManager.shared.getNickname() },
            imageURL: { URL(string: "\(NetworkManager.baseUrl)api/image/\($0)")! },
            lastVisitedAnimeId: { UserDefaultsManager.shared.getLastVisitedAnimeId() },
            // 탭을 고른다. 레거시는 탭 화면 전체를 한 겹 더 push했다 (TB4)
            showRanking: { router.select(.ranking) },
            showExplore: { year, season in
                appState.pushExplore(year: String(year), season: String(season))
                router.select(.research)
            }
        )
    )

    static let rankingBuilder: any RankingBuilding = RankingBuilder(
        dependencies: RankingDependencies(
            rankingClient: LiveRankingClient(client: AppSession.httpClient),
            metadataClient: LiveMetadataClient(),
            navigator: navigator
        )
    )

    static let reviewBuilder: any ReviewBuilding = makeReviewBuilder()

    private static func makeReviewBuilder() -> any ReviewBuilding {
        return ReviewBuilder(
            dependencies: ReviewDependencies(
                reviewClient: LiveReviewClient(client: AppSession.httpClient),
                navigator: navigator,
                analytics: AppAnalytics.tracker,
                openURL: { UIApplication.shared.open($0) },
                // 별점 남긴 애니 목록이 다시 불러온다 (레거시 WriteReviewViewModel.swift:54-57)
                onReviewWritten: {
                    await MainActor.run {
                        NotificationCenter.default.post(name: .reloadRatedAnime, object: nil)
                    }
                }
            )
        )
    }
}
