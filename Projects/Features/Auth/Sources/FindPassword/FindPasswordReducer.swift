import AuthClientInterface
import AuthInterface
import Foundation
import MVICore
import Navigation

/// 비밀번호 찾기 1단계: 인증번호. 동작 목록: notes/2026-10-29-R-auth-03-find-password.md (FP1~FP12)
struct FindPasswordReducer: Reducer {
    static let cooldown: TimeInterval = 30
    static let codeLifetime: TimeInterval = 180

    let authClient: any AuthClient
    let navigator: any Navigator
    /// 남은 시간은 끝나는 시각과 지금의 차로 계산한다 (레거시 Timer와 같이 앱이 멈췄다 돌아와도 맞다)
    var now: @Sendable () -> Date = { Date() }
    var tickInterval: Duration = .seconds(1)

    struct State: Equatable {
        var email = ""
        /// 처음부터 보인다 (레거시 초기값)
        var emailGuide = "이메일을 입력해주세요."
        var code = ""
        var codeGuide = ""
        var timerText = ""
        var sendButtonTitle = "인증번호 받기"
        var isSendEnabled = true
        var isNextEnabled = false
        var cooldownEnd: Date?
        var codeEnd: Date?
    }

    enum Intent: Sendable {
        case emailChanged(String)
        case codeChanged(String)
        case sendTapped
        case sendFinished(SendCodeResult)
        case sendFailed
        case cooldownTick
        case codeTimerTick
        case nextTapped
        case verifyFinished(VerifyCodeResult)
        case backTapped
    }

    private enum Timer {
        static let cooldown = "findPassword.cooldown"
        static let code = "findPassword.code"
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .emailChanged(let email):
            state.email = email
            state.emailGuide = EmailLoginReducer.emailGuide(for: email)
            return .none

        case .codeChanged(let code):
            state.code = code
            state.isNextEnabled = !code.isEmpty
            return .none

        case .sendTapped:
            state.isSendEnabled = false
            state.sendButtonTitle = "전송중..."
            state.codeGuide = ""
            let email = state.email
            return .run { [authClient] in
                guard let result = try? await authClient.sendVerificationCode(email: email) else {
                    return .sendFailed
                }
                return .sendFinished(result)
            }

        case .sendFinished(let result):
            state.emailGuide = ""
            switch result {
            case .sent:
                // 30초 재전송 대기와 3분 입력 제한을 함께 시작한다 (FP4)
                let start = now()
                state.cooldownEnd = start.addingTimeInterval(Self.cooldown)
                state.codeEnd = start.addingTimeInterval(Self.codeLifetime)
                state.isSendEnabled = false
                updateCooldown(&state)
                updateCodeTimer(&state)
                return .merge([
                    tick(Timer.cooldown, .cooldownTick), tick(Timer.code, .codeTimerTick),
                ])
            case .accountNotFound:
                resetSendButton(&state)
                state.emailGuide = "해당 이메일로 가입된 계정이 없습니다. 다시 확인해주세요."
            case .invalidEmail:
                resetSendButton(&state)
                state.emailGuide = "올바른 이메일 형식이 아닙니다."
            case .emptyEmail:
                resetSendButton(&state)
                state.emailGuide = "이메일 주소를 입력해 주세요."
            case .unexpected:
                // 레거시: 버튼이 "전송중..."·비활성인 채로 남는다 (FP6)
                break
            }
            return .none

        case .sendFailed:
            resetSendButton(&state)
            return .none

        case .cooldownTick:
            guard state.cooldownEnd != nil else {
                return .none
            }
            updateCooldown(&state)
            return state.cooldownEnd == nil ? .none : tick(Timer.cooldown, .cooldownTick)

        case .codeTimerTick:
            guard state.codeEnd != nil else {
                return .none
            }
            updateCodeTimer(&state)
            return state.codeEnd == nil ? .none : tick(Timer.code, .codeTimerTick)

        case .nextTapped:
            let (email, code) = (state.email, state.code)
            return .run { [authClient] in
                guard let result = try? await authClient.verifyCode(email: email, code: code) else {
                    return nil
                }
                return .verifyFinished(result)
            }

        case .verifyFinished(let result):
            switch result {
            case .verified:
                return .run { [navigator] in
                    await navigator.push(AuthRoute.resetPassword)
                    return nil
                }
            case .emptyCode:
                state.codeGuide = "수신하신 인증번호를 입력해 주세요."
            case .wrongCode:
                state.codeGuide = "인증번호가 올바르지 않습니다."
            case .expired:
                state.codeGuide = "유효 시간이 만료되었습니다. 재발송 후 다시 시도해주세요."
            case .unexpected:
                break
            }
            return .none

        case .backTapped:
            return .run { [navigator] in
                await navigator.pop()
                return nil
            }
        }
    }

    private func resetSendButton(_ state: inout State) {
        state.isSendEnabled = true
        state.sendButtonTitle = "인증번호 받기"
    }

    /// 0이 되면 "인증번호 재전송"으로 다시 누를 수 있다 (FP5)
    private func updateCooldown(_ state: inout State) {
        guard let end = state.cooldownEnd else {
            return
        }
        let remaining = max(0, Int(end.timeIntervalSince(now())))
        if remaining == 0 {
            state.cooldownEnd = nil
            state.isSendEnabled = true
            state.sendButtonTitle = "인증번호 재전송"
        } else {
            state.sendButtonTitle = String(format: "전송됨 %02d:%02d", remaining / 60, remaining % 60)
        }
    }

    /// 0이 되면 만료 안내 (FP7)
    private func updateCodeTimer(_ state: inout State) {
        guard let end = state.codeEnd else {
            return
        }
        let remaining = max(0, Int(end.timeIntervalSince(now())))
        state.timerText = String(format: "%d:%02d", remaining / 60, remaining % 60)
        if remaining == 0 {
            state.codeEnd = nil
            state.codeGuide = "유효 시간이 만료되었습니다. 재발송 후 다시 시도해주세요."
        }
    }

    private func tick(_ id: String, _ intent: Intent) -> Effect<Intent> {
        return .run(id: id) { [tickInterval] in
            try? await Task.sleep(for: tickInterval)
            return intent
        }
    }
}
