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
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            Group {
                AppDIContainer.makeContentView()
//                if isLoggedIn == false {
//                    AppDIContainer.makeContentView()
//                    //AppDIContainer.makeHomeView()
//                } else {
//                    AppDIContainer.makeLoginView()
//                }
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
                case .review:
                    AppDIContainer.makeReviewView()
                case .explore:
                    AppDIContainer.makeExploreView()
                case .animeDetail(let animeId):
                    AppDIContainer.makeAnimeDetailView(animeId: animeId)
                case .resetPassword:
                    AppDIContainer.makeResetPassword()
                case .content:
                    AppDIContainer.makeContentView()
                case .setting:
                    AppDIContainer.makeSettingView()
                default:
                    Text("asdfasdf")
                }
            }
        }
    }
}
