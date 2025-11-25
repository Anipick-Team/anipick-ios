//
//  AppEntryView.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import SwiftUI

struct AppEntryView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @StateObject var viewModel = AppEntryViewModel()
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            Group {
                if UserDefaultsManager.shared.getAccessToken().isEmpty {
                    AppDIContainer.makeLoginView()
                } else {
                    AppDIContainer.makeContentView(activeTab: .home)
                }
            }
            .background(Color.white)
            .onAppear {
                TokenInterceptor.shared.navigationManager = navigationManager
                viewModel.fetchMataData()
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .emailSignup:
                    AppDIContainer.makeEmailSignupView()
                case .emailLogin:
                    AppDIContainer.makeEmailLoginView()
                case .LoginProblem:
                    LoginProblemView()
                case .findPassword:
                    AppDIContainer.makeFindPasswordView()
                case .homeSearch:
                    AppDIContainer.makeHomeSearchView()
                case .homeView:
                    AppDIContainer.makeHomeView()
                case .editNickname:
                    AppDIContainer.makeEditNicknameView()
                case .editEmail:
                    AppDIContainer.makeEditEmailView()
                case .editPassword:
                    AppDIContainer.makeEditPasswordView()
                case .deleteAccount:
                    AppDIContainer.makeWithdrawalView()
                case .myInfoInToWatchList:
                    AppDIContainer.makeMyInfoInToWatchView()
                case .myInfo:
                    AppDIContainer.makeMyInfoView()
                case .myInfoWatchingList:
                    AppDIContainer.makeMyInfoInWatchingListView()
                case .finishedWatchList:
                    AppDIContainer.makeMyInfoFinishedWatchingView()
                case .likeAnimeList:
                    AppDIContainer.makeMyInfoLikeAnimeView()
                case .likePersonList:
                    AppDIContainer.makeMyInfoLikePersonView()
                case .ratedAnimeList:
                    AppDIContainer.makeMyInfoRatedAnimeView()
                case .ranking:
                    AppDIContainer.makeRakingView()
                case .research:
                    AppDIContainer.makeResearchView()
                case .review(let starRating, let animeId):
                    AppDIContainer.makeReviewView(starRating: starRating, animeId: animeId)
                case .explore(let season, let seaseonYear):
                    AppDIContainer.makeExploreView(season: season, year: seaseonYear)
                case .animeDetail(let animeId):
                    AppDIContainer.makeAnimeDetailView(animeId: animeId)
                case .resetPassword:
                    AppDIContainer.makeResetPassword()
                case .content(let activeTab):
                    AppDIContainer.makeContentView(activeTab: activeTab)
                case .setting:
                    AppDIContainer.makeSettingView()
                case .inquiry:
                    InquiryView()
                case .preferenceSelection:
                    AppDIContainer.makePreferenceSelectionView()
                case .commingSoonDetail:
                    AppDIContainer.makeCommingSoonView()
                case .mainLoginView:
                    AppDIContainer.makeLoginView()
                case .recentReview:
                    AppDIContainer.makeRecentReviewView()
                case .recommendView(let animeId):
                    AppDIContainer.makeRecommendationView(animeId: animeId)
                case .producerDetail(let studioId):
                    AppDIContainer.makeProducerDetailView(studioId: studioId)
                case .voiceActorDetail(let animeId):
                    AppDIContainer.makeVoiceActorDetailView(animeId: animeId)
                case .characterAndVoiceActorDetail(let animeId):
                    AppDIContainer.makeCharacterAndVoiceActorDetailVIew(animeId: animeId)
                case let .seriesDetail(animeId, animeTitle):
                    AppDIContainer.makeSeriesDetialView(animeId: animeId, animeTitle: animeTitle)
                    
                case let .recommend(animeId, animeTitle):
                    AppDIContainer.makeRecommendView(animeId: animeId, animeTitle: animeTitle)
                default:
                    Text("asdfasdf")
                }
            }
        }
        .background(Color.white)
    }
}
