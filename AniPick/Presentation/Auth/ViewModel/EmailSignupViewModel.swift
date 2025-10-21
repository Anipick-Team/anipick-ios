//
//  EmailSigninViewModel.swift
//  AniPick
//
//  Created by cho on 4/27/25.
//

import SwiftUI

@MainActor
class EmailSignupViewModel: ObservableObject {
    @Published var isAgreeAll: Bool = false
    @Published var isAgreeOverFourteen: Bool = false
    @Published var isAgreeTermsOfUse: Bool = false
    @Published var isAgreePrivacyPolicy: Bool = false
    
    @Published var emailGuideText: String = ""
    @Published var passwordGuideText: String = ""
    
    @Published var emailString: String = "" {
        didSet {
            DLog(emailString)
            validateEmailInputs()
        }
    }
    @Published var passwordString: String = "" {
        didSet {
            validateInputs()
            isPasswordValid()
            validNewPasswordInputs()
        }
    }
    
    @Published var isEnableLoginButton: Bool = false
    @Published var isValidatePassword: Bool = false {
        didSet {
            isValidPassword()
        }
    }
    
    private let authUsecase: AuthUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(authUsecase: AuthUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.authUsecase = authUsecase
        self.navigationManager = navigationManager
    }
}

extension EmailSignupViewModel {
    func signupWithEmail() async {
        do {
            let request = EmailSignupRequest(
                email: self.emailString,
                password: self.passwordString,
                termsAndConditions: self.isAgreeAll
            )
            let response = try await authUsecase.postEmailSignup(request: request)
            if response.code == 200 {
                UserDefaultsManager.shared.setAccessToken(accessToken: response.result?.token?.accessToken ?? "")
                DLog("\(UserDefaultsManager.shared.getAccessToken())")
                UserDefaultsManager.shared.setRefreshToken(refreshToken: response.result?.token?.refreshToken ?? "")
                UserDefaultsManager.shared.setNickname(response.result?.nickname ?? "nickname - null")
                UserDefaultsManager.shared.setEmail(self.emailString)
                UserDefaultsManager.shared.setSNSAccount(sns: "")
                self.navigationManager.push(route: .preferenceSelection)
                // self.navigationManager.push(route: .content)
            } else if response.code == 109 {
                self.emailGuideText = "이미 가입한 이메일입니다."
            }
            // TODO: UserName, id, accessToken, refreshToken -  UserDefaults에 저장 - Email 회원가입 정리
        } catch {
            DLog("signup with email error - \(error.localizedDescription)")
        }
    }
}

extension EmailSignupViewModel {
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
        
        self.isEnableLoginButton = !emailString.isEmpty && !passwordString.isEmpty && self.isAgreeAll
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }
    
    
    func validateInputs()  {
        print("validateInputs 호출호출!")

        self.isEnableLoginButton = !emailString.isEmpty && !passwordString.isEmpty && self.isAgreeAll
    }

    func validNewPasswordInputs() {
        if self.passwordString.isEmpty {
            self.passwordGuideText = ""
        } else if isValidPassword() == false {
            self.passwordGuideText = "8~16자의 영문 대/소문자, 숫자, 특수문자를 조합하여 입력해 주세요."
        } else {
            self.passwordGuideText = ""
        }
    }

    
    func isValidPassword() -> Bool {
        var password = self.passwordString
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
         // let regex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[!@#$%^&*()_+=-]).{8,16}$"
        let regex = "^(?=.*[A-Za-z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).{8,16}$"
        let result = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
        
        return result
    }
    
    func isPasswordValid()  {
        
        let stringCount = passwordString.count >= 10
        
        // hasLetter - 영문자가 하나라도 포함되어 있으면 true
        let hasLetter = passwordString.range(of: "[a-zA-Z]", options: .regularExpression) != nil
        // hasNumber - 숫자가 하나라도 포함되어 있으면 true
        let hasNumber = passwordString.rangeOfCharacter(from: .decimalDigits) != nil
        // hasSpecialtrue - 특수문자가 하나라도 있으면 true
        let specialCharRegex = "[^A-Za-z0-9]"
        let hasSpecialChar = passwordString.range(of: specialCharRegex, options: .regularExpression) != nil
       
        let trueCount = [hasLetter, hasNumber, hasSpecialChar].filter { $0 }.count
        
        self.isValidatePassword = stringCount && trueCount >= 2
    }
    
    // MARK: - 이메일 확인 함수
    
    
    
    
    
    // MARK: - 이용약관 동의 관련 함수
    func toggleAllAgreement() {
        let agreement = !self.isAgreeAll
        self.isAgreeAll = agreement
        self.isAgreeOverFourteen = agreement
        self.isAgreeTermsOfUse = agreement
        self.isAgreePrivacyPolicy = agreement
        self.validateInputs()
    }
    
    func toggleOverFourteen() {
        self.isAgreeOverFourteen.toggle()
        self.updateAllAgreement()
    }
    
    func toggleTermsOfUse() {
        self.isAgreeTermsOfUse.toggle()
        self.updateAllAgreement()
    }
    
    func moveToTermsOfUse() {
        let url = URL(string: "https://anipick.p-e.kr/terms.html")!
        UIApplication.shared.open(url)
    }
    
    func moveToPrivacyPolicy() {
        let url = URL(string: "https://anipick.p-e.kr/privacy.html")!
        UIApplication.shared.open(url)
    }
    
    func togglePrivacyPolicy() {
        self.isAgreePrivacyPolicy.toggle()
        self.updateAllAgreement()
    }
    
    private func updateAllAgreement() {
        self.isAgreeAll = self.isAgreeOverFourteen && self.isAgreeTermsOfUse && self.isAgreePrivacyPolicy
        self.validateInputs()
    }
    
}


