//
//  ForgetPasswordViewModel.swift
//  AniPick
//
//  Created by cho on 4/27/25.
//

import SwiftUI

class ForgetPasswordViewModel: ObservableObject {
    @Published var emailGuideText: String = "3:00"
    @Published var validNumeberGuideText: String = ""
    @Published var timerCount: String = ""
    
    @Published var emailString: String = "" {
        didSet {
            DLog(emailString)
            validateEmailInputs()
        }
    }
    
    @Published var newPassword: String = ""
    @Published var checkNewPassword: String = "" {
        didSet {
            checkPassword()
        }
    }
    
    @Published var verificationCode: String = "" {
        didSet {
            isVerificationCodeValid()
        }
    }
    
    @Published var isEnableFindPasswordButton: Bool = false
    @Published var activeNextButton: Bool = false
    
    private let authUsecase: AuthUsecaseProtocol
    private let navigationManager: NavigationManager
    
    init(authUsecase: AuthUsecaseProtocol,
         navigationManager: NavigationManager) {
        self.authUsecase = authUsecase
        self.navigationManager = navigationManager
    }
    
    func isVerificationCodeValid() {
        self.activeNextButton = verificationCode.isEmpty == false
    }
    
    func checkPassword() {
        self.isEnableFindPasswordButton = checkNewPassword.isEmpty == false
    }
    
    func validateEmailInputs()  {
        print("validateInputs 호출호출!")
        // TODO: 해당 이메일이 없다면, "해당 이메일로 가입된 계정이 없습니다. 다시 확인해주세요."
        if self.emailString.isEmpty {
            self.emailGuideText = "이메일을 입력해주세요."
        } else if self.isValidEmail(emailString) == false {
            self.emailGuideText = "올바른 이메일 형식이 아닙니다."
        } else {
            self.emailGuideText = ""
        }
        
   //     self.isEnableLoginButton = !emailString.isEmpty && !passwordString.isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }
    
    func tappedValidNumberButton() async {
        // TODO: 인증번호 받고 처리하는 로직 필요
        do {
            let response = try await authUsecase.sendEmailVerificationCode(
                email: self.emailString
            )
            if response.code == 200 {
                self.navigationManager.push(route: .resetPassword)
            }
        } catch {
            DLog("validNumber Error - \(error.localizedDescription)")
        }
    }
    
    func tappedNextButton() async {
        do {
            let request = VerifyVerificationCodeRequest(email: self.emailString, code: self.verificationCode)
            let response = try await authUsecase.verifyEmailVerificationCode(request: request)
            if response.code == 200 {
                self.navigationManager.push(route: .content(activeTab: .home))
            }
        } catch {
            DLog("eerrorororor")
        }
    }
    
    func resetPassword() async {
        do {
            let request = ResetPasswordRequest(
                email: self.emailString,
                newPassword: newPassword,
                checkNewPassword: checkNewPassword
            )
            let response = try await authUsecase.resetPassword(request: request)
            if response.code == 200 {
                self.navigationManager.push(route: .content(activeTab: .home))
            } else {
                DLog("비밀번호 변경 실패")
            }
        } catch {
            DLog("resetPassword error - \(error.localizedDescription)")
        }
    }
}
