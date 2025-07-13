//
//  AppDIContainer.swift
//  AniPick
//
//  Created by cho on 6/8/25.
//
import SwiftUI

@MainActor
struct AppDIContainer {
    static let navigationManager = NavigationManager()
    
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
    
    static func makeExploreView() -> some View {
        let apiService = ExploreAPIService()
        let repository = ExploreRepository(apiService: apiService)
        let usecase = ExploreUsecase(exploreRepository: repository)
        let viewModel = ExploreViewModel(usecase: usecase)
        
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
}
