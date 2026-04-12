//
//  EmailLoginViewModel.swift
//  AniPick
//
//  Created by cho on 4/27/25.
//

import SwiftUI

@MainActor
class EmailLoginViewModel: ObservableObject {
    @Published var emailString: String = "" {
        didSet {
            DLog(emailString)
            validateEmailInputs()
        }
    }

    @Published var passwordString: String = "" {
        didSet {
            DLog(passwordString)
            validPasswordInputs()
            validateInputs()
        }
    }
    
    @Published var emailGuideText: String = ""
    @Published var passwordGuideText: String = ""
    @Published var commonGuideText: String = ""

    @Published var isEnableLoginButton: Bool = false
    @Published var isShowWithdrawlUserPopup: Bool = false
    
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
            self.clearGuideText()
            if response.code == 200 {
                if let result = response.result {
                    UserDefaultsManager.shared.setAccessToken(accessToken: result.token?.accessToken ?? "")
                    DLog("\(UserDefaultsManager.shared.getAccessToken())")
                    UserDefaultsManager.shared.setRefreshToken(refreshToken: result.token?.refreshToken ?? "")
                    UserDefaultsManager.shared.setNickname(result.nickname ?? "---")
                    UserDefaultsManager.shared.setEmail(self.emailString)
                    DLog("\(UserDefaultsManager.shared.getNickname())")
                    UserDefaultsManager.shared.setSNSAccount(sns: "")
                    AnalyticsManager.logLogin(method: "email")
                    self.navigationManager.push(route: AppRoute.content(activeTab: .home))
                }
            } else if response.code == 110 {
                self.passwordGuideText = "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해주세요."
            } else if response.code == 104 || response.code == 106 || response.code == 101 {
                self.commonGuideText = "이메일이나 비밀번호를 확인해주세요."
            } else if response.code == 105 {
                self.passwordGuideText = "비밀번호를 입력해주세요."
            }  else if response.code == 112 {
                self.emailGuideText = "가입된 계정이 없습니다. 이메일을 다시 확인해주세요."
            } else if response.code == 132 {
                self.isShowWithdrawlUserPopup.toggle()
                
            } else if response.code == 102 {
                self.emailGuideText = "이메일 주소를 입력해 주세요."
            }
            
        } catch {
            DLog("login with email failed - \(error.localizedDescription)")
        }
    }

    private func clearGuideText() {
        self.emailGuideText = ""
        self.commonGuideText = ""
        self.passwordGuideText = ""
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
    
    func validPasswordInputs() {
        if self.passwordString.isEmpty {
            self.passwordGuideText = "비밀번호를 입력해주세요."
        } else if isValidPassword(self.passwordString) == false {
            self.passwordGuideText = "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
        } else {
            self.passwordGuideText = ""
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
    
    func isValidPassword(_ password: String) -> Bool {
        // 최소 1개 대문자, 1개 소문자, 1개 숫자, 1개 특수문자 포함, 전체 8~16자
        // let regex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,16}$"
        let regex = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,16}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: password)
    }
    
    func popToMainLoginView() {
        self.navigationManager.pop()
    }

}
