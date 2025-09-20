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
            DLog(emailString)
            validateEmailInputs()
        }
    }
    
    @Published var emailGuideText: String = ""
    

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
                if let result = response.result {
                    UserDefaultsManager.shared.setAccessToken(accessToken: result.token?.accessToken ?? "")
                    DLog("\(UserDefaultsManager.shared.getAccessToken())")
                    UserDefaultsManager.shared.setRefreshToken(refreshToken: result.token?.refreshToken ?? "")
                    UserDefaultsManager.shared.setNickname(result.nickname ?? "---")
                    UserDefaultsManager.shared.setEmail(self.emailString)
                    DLog("\(UserDefaultsManager.shared.getNickname())")
                    UserDefaultsManager.shared.setSNSAccount(sns: "")
                    self.navigationManager.push(route: AppRoute.content(activeTab: .home))
                }
            }
            
        } catch {
            DLog("login with email failed - \(error.localizedDescription)")
        }
    }

    private func moveToHomeView() {
        self.navigationManager.push(route: AppRoute.content(activeTab: .home))
    }
    
    func validateEmailInputs()  {
        DLog("validateInputs 호출호출!")
        // TODO: 이미 가입한 이메일일 경우, "이미 가입한 이메일입니다. 표시"
        if self.emailString.isEmpty {
            self.emailGuideText = "이메일을 입력해주세요."
        } else if self.isValidEmail(emailString) == false {
            self.emailGuideText = "올바른 이메일 형식이 아닙니다."
        } else {
            self.emailGuideText = ""
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }
    
    func validateInputs()  {
        print("validateInputs 호출호출!")
        self.isEnableLoginButton = !emailString.isEmpty && !passwordString.isEmpty
    }
}
