//
//  EmailLoginViewModel.swift
//  AniPick
//
//  Created by cho on 4/27/25.
//

import SwiftUI

class EmailLoginViewModel: ObservableObject {
    @Published var emailString: String = "" {
        didSet {
            print(emailString)
            validateInputs()
        }
    }
    @Published var passwordString: String = "" {
        didSet {
            print(passwordString)
            validateInputs()
        }
    }
    
    @Published var isEnableLoginButton: Bool = false
    
    private let authUsecase: AuthUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(authUsecase: AuthUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.authUsecase = authUsecase
        self.navigationManager = navigationManager
    }
}

extension EmailLoginViewModel {
    func loginWithEmail() async {
        do {
            // TODO: UserName, id, accessToken, refreshToken -  UserDefaults에 저장 - Email 회원가입 정리
            let request = EmailLoginRequest(
                email: self.emailString,
                password: self.passwordString
            )
            let response = try await authUsecase.postEmailLogin(request: request)
            DLog("loginWithEmail - \(response)")
            
            if response.code == 200 {
                UserDefaultsManager.shared.setAccessToken(accessToken: response.result?.token?.accessToken ?? "")
                UserDefaultsManager.shared.setRefreshToken(refreshToken: response.result?.token?.refreshToken ?? "")
                self.navigationManager.push(route: AppRoute.homeView)
            }
            
        } catch {
            DLog("login with email failed - \(error.localizedDescription)")
        }
    }

    private func moveToHomeView() {
        self.navigationManager.push(route: AppRoute.homeView)
    }
    func validateInputs()  {
        print("validateInputs 호출호출!")
        self.isEnableLoginButton = !emailString.isEmpty && !passwordString.isEmpty
    }
}
