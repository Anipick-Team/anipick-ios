//
//  AppEntryView.swift
//  AniPick
//
//  Created by cho on 6/22/25.
//

import SwiftUI

struct AppEntryView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
      //     AppDIContainer.makeLoginView()
      //      AppDIContainer.makeHomeView()
          //  AppDIContainer.makeSettingView()
            AppDIContainer.makeMyInfoView()
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
                    default:
                        Text("asdfasdf")
                    }
                }
        }
    }
}
