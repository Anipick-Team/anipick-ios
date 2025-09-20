//
//  ForgetPasswordViewModel.swift
//  AniPick
//
//  Created by cho on 4/27/25.
//

import SwiftUI

@MainActor
class ForgetPasswordViewModel: ObservableObject {
    private var timer: Timer?
    private var endDate: Date?
    private var isRunning = false
    
    
    @Published var emailGuideText: String = "이메일을 입력해주세요."
    @Published var validNumeberGuideText: String = ""
    @Published var timerCount: String = ""
    @Published var validNumButtonText: String = "인증번호 받기"
    @Published var isTappedValidNumButton: Bool = false
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
    
    func sendCodeAndStartTimer() async {
        startCountdown(duration: 180)  // 3분
    }
    
    func startCountdown(duration: TimeInterval) {
           guard !isRunning else { return }
           isRunning = true
           endDate = Date().addingTimeInterval(duration)

           updateText()

           timer?.invalidate()
           timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
               Task { @MainActor in self?.tick() }
           }
           RunLoop.main.add(timer!, forMode: .common)

       }
    
    private func updateText() {
        guard let end = endDate else { return }
        let remain = max(0, Int(end.timeIntervalSinceNow))
        validNumButtonText = formatted(remain)
        if remain == 0 { stopCountdown(resetText: true) }
    }
    
    private func tick() {
        guard let end = endDate else { stopCountdown(resetText: true); return }
        let remain = max(0, Int(end.timeIntervalSinceNow))
        if remain == 0 { stopCountdown(resetText: true); return }
        validNumButtonText = formatted(remain)
    }
    
    private func stopCountdown(resetText: Bool) {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endDate = nil
        if resetText { validNumButtonText = "인증번호 재전송" }
    }

    private func formatted(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "전송됨 %d:%02d", m, s)
    }

    deinit { timer?.invalidate() }
    
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
        await self.sendCodeAndStartTimer()
        self.isTappedValidNumButton = true
        do {
            let response = try await authUsecase.sendEmailVerificationCode(
                email: self.emailString
            )
            DLog("validNum Response - \(response)")
            self.emailGuideText = ""
            self.validNumeberGuideText = ""
            if response.code == 200 {
                DLog("인증번호 전송 성공")
                self.validNumButtonText = "전송됨"
               // self.navigationManager.push(route: .resetPassword)
            } else if response.code == 112 {
                self.emailGuideText = "해당 이메일로 가입된 계정이 없습니다. 다시 확인해주세요."
            } else if response.code == 103 {
                self.emailGuideText = "올바른 이메일 형식이 아닙니다."
            } else if response.code == 102 {
                self.emailGuideText = "이메일 주소를 입력해 주세요."
            }
        } catch {
            DLog("validNumber Error - \(error.localizedDescription)")
        }
    }
    
    func tappedNextButton() async {
        do {
            let request = VerifyVerificationCodeRequest(email: self.emailString, code: self.verificationCode)
            let response = try await authUsecase.verifyEmailVerificationCode(request: request)
            DLog("비번찾기 다음 버튼 탭탭 - \(response)")
            if response.code == 200 {
               // self.navigationManager.push(route: .content(activeTab: .home))
                self.navigationManager.push(route: .resetPassword)
                UserDefaultsManager.shared.setEmail(self.emailString)
                DLog("emailString 확인 - \(self.emailString)")
            } else if response.code == 113 {
                self.validNumeberGuideText = "수신하신 인증번호를 입력해 주세요."
            } else if response.code == 114 {
                self.validNumeberGuideText = "인증번호가 올바르지 않습니다."
            } else if response.code == 115 {
                self.validNumeberGuideText = "유효 시간이 만료되었습니다. 재발송 후 다시 시도해주세요."
            }
        } catch {
            DLog("eerrorororor")
        }
    }
    
    func resetPassword() async {
        do {
            let request = ResetPasswordRequest(
                email: UserDefaultsManager.shared.getEmail(),
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
