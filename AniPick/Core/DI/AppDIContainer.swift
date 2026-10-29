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
    static let navigationManager = NavigationManager()
    static let appState = AppState(navigationManager: navigationManager)
    static let sessionState = SessionState(navigationManager: navigationManager)
    static let navigator = LegacyNavigator(navigationManager: navigationManager)

    // MARK: - 새 Feature 빌더 (이관 Phase 3). 레거시 make…View는 1릴리스 유지 (R13)
    static let settingBuilder: any SettingBuilding = SettingBuilder(
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

    static let authBuilder: any AuthBuilding = AuthBuilder(
        dependencies: AuthDependencies(
            authClient: liveAuthClient,
            exploreClient: LiveExploreClient(client: AppSession.httpClient),
            reviewClient: LiveReviewClient(client: AppSession.httpClient),
            metadataClient: LiveMetadataClient(client: AppSession.httpClient),
            navigator: navigator,
            analytics: AppAnalytics.tracker,
            onLoginCompleted: { navigationManager.completeLogin() },
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

    static let exploreBuilder: any ExploreBuilding = ExploreBuilder(
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
                    let cancellable = appState.$pendingExploreFilter.dropFirst().sink { _ in
                        continuation.yield()
                    }
                    continuation.onTermination = { _ in cancellable.cancel() }
                }
            },
            // 레거시 CommunityDetailViewModel.makeShareItems와 같은 링크
            sharePost: { postId in
                ShareSheet.present(items: DeepLink.communityPost(id: postId).universalLink.map { [$0] } ?? [])
            }
        )
    )

    static let myInfoBuilder: any MyInfoBuilding = MyInfoBuilder(
        dependencies: MyInfoDependencies(
            myInfoClient: LiveMyInfoClient(
                client: AppSession.httpClient,
                imageBaseURL: URL(string: NetworkManager.baseUrl)!
            ),
            reviewClient: LiveReviewClient(client: AppSession.httpClient),
            navigator: navigator,
            ratedReviewsReloadNotification: .reloadRatedAnime,
            // 레거시 MyContentView: 루트로 돌아간 뒤 그 탭의 ContentView를 push한다
            openTab: { tab in
                navigationManager.popToRoot()
                navigationManager.push(route: .content(activeTab: Tab(tab)))
            },
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
            // 레거시 HomeViewModel.moveToRankingView·moveToExploreView 그대로 (탭 구조는 Phase 4)
            showRanking: { navigationManager.push(route: .content(activeTab: .ranking)) },
            showExplore: { year, season in
                appState.pushExplore(year: String(year), season: String(season))
                navigationManager.push(route: .content(activeTab: .research))
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

    static let reviewBuilder: any ReviewBuilding = ReviewBuilder(
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
    
    static func makeLoginView() -> some View {
        let apiService = AuthAPIService()
        let repository = AuthRepository(apiService: apiService)
        let usecase = AuthUsecase(authRepository: repository)
        let viewModel = MainLoginViewModel(authUsecase: usecase,
                                           navigationManager: navigationManager)
        
        return MainLoginView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeEmailSignupView() -> some View {
        let apiService = AuthAPIService()
        let repository = AuthRepository(apiService: apiService)
        let usecase = AuthUsecase(authRepository: repository)
        let viewModel = EmailSignupViewModel(authUsecase: usecase,
                                             navigationManager: navigationManager)
        
        return EmailSignupView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeEmailLoginView() -> some View {
        let apiService = AuthAPIService()
        let repository = AuthRepository(apiService: apiService)
        let usecase = AuthUsecase(authRepository: repository)
        let viewModel = EmailLoginViewModel(authUsecase: usecase,
                                            navigationManager: navigationManager)
        
        return EmailLoginView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeHomeView() -> some View {
        let apiService = HomeAPIService()
        let repository = HomeRepository(apiService: apiService)
        let usecase = HomeUsecase(repo: repository)
        let viewModel = HomeViewModel(usecase: usecase,
                                      navigationManager: navigationManager)
        
        return HomeView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeExploreView(season: Int? = nil, year: Int? = nil) -> some View {
        let apiService = ExploreAPIService()
        let repository = ExploreRepository(apiService: apiService)
        let usecase = ExploreUsecase(exploreRepository: repository)
        let viewModel = ExploreViewModel(usecase: usecase, navigationManager: navigationManager)
        
        return ExploreView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeFindPasswordView() -> some View {
        let apiService = AuthAPIService()
        let repository = AuthRepository(apiService: apiService)
        let usecase = AuthUsecase(authRepository: repository)
        let viewModel = ForgetPasswordViewModel(authUsecase: usecase,
                                                navigationManager: navigationManager)
        return ForgetPasswordView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeHomeSearchView() -> some View {
        let apiService = SearchAPIService()
        let repository = SearchRepository(apiService: apiService)
        let usecase = SearchUsecase(searchRepository: repository)
        let viewModel = HomeSearchViewModel(usecase: usecase,
                                            navigationManager: navigationManager)
        
        return HomeSearchView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    
    // TODO: Setting 관련 API 연결 필요
    static func makeSettingView() -> some View {
        let viewModel = SettingViewModel(navigationManager: navigationManager)
        
        return SettingView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    static func makeEditNicknameView() -> some View {
        let viewModel = EditNicknameViewModel(navigationManager: navigationManager)
        
        return EditNicknameView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeEditEmailView() -> some View {
        let viewModel = EditEmailViewModel(navigationManager: navigationManager)
        return EditEmailView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeEditPasswordView() -> some View {
        let viewModel = EditPasswordViewModel(navigationManager: navigationManager)
        return EditPasswordView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeWithdrawalView() -> some View {
        let viewModel = WithdrawalViewModel(navigationManager: navigationManager)
        return WithdrawalView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }

    static func makeAdultSettingView() -> some View {
        let viewModel = AdultSettingViewModel(navigationManager: navigationManager)
        return AdultSettingView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeRecommemnd2View(animeId: Int, animeTitle: String?) -> some View {
        let viewModel = RecommendViewModel(navigationManager: navigationManager, animeId: animeId, animeTitle: animeTitle)
        return RecommendedAnimeView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
}



extension AppDIContainer {
    static func makeMyInfoView() -> some View {
        let viewModel = MyInfoViewModel(navigationManager: navigationManager)
        return MyInfoView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    static func makeMyInfoInToWatchView() -> some View {
        let viewModel = MyInfoViewModel(navigationManager: navigationManager)
        
        return ToWatchListView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeMyInfoInWatchingListView() -> some View {
        let viewModel = MyInfoViewModel(navigationManager: navigationManager)
        
        return WatchingListView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeMyInfoFinishedWatchingView() -> some View {
        let viewModel = MyInfoViewModel(navigationManager: navigationManager)
        
        return FinishedWatchingListView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeMyInfoRatedAnimeView() -> some View {
        let viewModel = RatedAnimeListViewModel(navigationManager: navigationManager)
        return RatedAnimeListView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeMyInfoLikeAnimeView() -> some View {
        let viewModel = LikeAnimeListViewModel(navigationManager: navigationManager)
        return LikeAnimeListView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeMyInfoLikePersonView() -> some View {
        let viewModel = LikePersonViewModel(navigationManager: navigationManager)
        return LikePersonListView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    // MARK: Ranking
    static func makeRakingView() -> some View {
        let viewModel = RankingViewModel(navigationManager: navigationManager)
        return RankingView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    // MARK: Research
    static func makeResearchView() -> some View {
        let viewModel = ResearchViewModel(navigationManager: navigationManager)
        return ResearchView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeReviewView(starRating: Double, animeId: Int, reviewContent: String) -> some View {
        let viewModel = WriteReviewViewModel(navigationManager: navigationManager, starRating: starRating, animeId: animeId, reviewContent: reviewContent)
        return WriteReviewView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeAnimeDetailView(animeId: Int) -> some View {
        let viewModel = AnimationInfoViewModel(animeId: animeId, navigationManager: navigationManager)
        return AnimationInfoView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeResetPassword() -> some View {
        let apiService = AuthAPIService()
        let repository = AuthRepository(apiService: apiService)
        let usecase = AuthUsecase(authRepository: repository)
        let viewModel = ForgetPasswordViewModel(
            authUsecase: usecase,
            navigationManager: navigationManager)
        
        return NewPasswordView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeContentView(activeTab: Tab) -> some View {
        let viewModel = ContentViewModel(activeTab: activeTab, navigationManager: navigationManager)
        return ContentView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makePreferenceSelectionView() -> some View {
        let viewModel = PreferenceSelectionViewModel(navigationManager: navigationManager)
        return PreferenceSelectionView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeComingSoonView() -> some View {
        let viewModel = ComingSoonViewModel(navigationManager: navigationManager)
        return ComingSoonView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }

    static func makeWeekdayNewAnimeView(day: Int) -> some View {
        let viewModel = WeekdayNewAnimeViewModel(day: day, navigationManager: navigationManager)
        return WeekdayNewAnimeView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeRecentReviewView() -> some View {
        let viewModel = RecentReviewViewModel(navigationManager: navigationManager)
        return RecentReviewView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeRecommendationView(animeId: Int?) -> some View {
        let viewModel = SimilarRecommendedAnimeViewModel(navigationManager: navigationManager, animeId: animeId)
        return SimilarRecommendedAnimeView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeProducerDetailView(studioId: Int) -> some View {
        let viewModel = ProducerDetailViewModel(navigationManager: navigationManager, studioId: studioId)
        return ProducerDetailView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeVoiceActorDetailView(animeId: Int) -> some View {
        let viewModel = VoiceActorViewModel(navigationManager: navigationManager, animeId: animeId)
        return VoiceActorDetailView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeCharacterAndVoiceActorDetailVIew(animeId: Int) -> some View {
        let viewModel = PersonDetailViewModel(navigationManager: navigationManager, animeId: animeId)
        return PersonDetailView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeSeriesDetialView(animeId: Int, animeTitle: String) -> some View {
        let viewModel = SeriesDetailViewModel(navigationManager: navigationManager, animeId: animeId, animeTitle: animeTitle)
        return SeriesDetailView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
    
    static func makeRecommendView(animeId: Int, animeTitle: String) -> some View {
        let viewModel = RecommendedViewModel(navigationManager: navigationManager, animeId: animeId, animeTitle: animeTitle)
        
        return RecommendedView(viewModel: viewModel)
            .environmentObject(navigationManager)
    }
}

extension Tab {
    init(_ tab: MainTab) {
        switch tab {
        case .home:
            self = .home
        case .ranking:
            self = .ranking
        case .explore:
            self = .research
        case .myInfo:
            self = .myInfo
        }
    }
}
