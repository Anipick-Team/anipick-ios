import ClientCore
import Foundation

/// 소셜 로그인 수단. 원시값은 서버 경로·저장하는 sns 값·분석 이벤트에 그대로 쓴다
public enum SocialProvider: String, CaseIterable, Sendable {
    case kakao
    case google
    case apple
}

/// 이미 다른 수단으로 가입된 계정 (서버 133~136)
public enum ExistingAccount: Equatable, Sendable {
    case email
    case kakao
    case google
    case apple
}

/// 소셜 로그인 결과 (`POST api/oauth/{provider}/callback`)
public enum SocialLoginResult: Equatable, Sendable {
    /// 200. 토큰·sns·닉네임·userId는 Client가 저장했다
    case success(LoggedInUser)
    /// 132
    case withdrawn
    /// 133~136
    case existingAccount(ExistingAccount)
    case unexpected(code: Int)
}

/// SDK에서 토큰을 얻지 못함
public enum SocialSignInFailure: Error, Sendable {
    /// 오류 객체 없는 실패 — 로그인 이슈로 남긴다 (사유)
    case issue(String)
    /// SDK 오류 — 비치명 오류로 남긴다
    case sdk(NSError)
}

/// 로그인에 성공한 사용자 (토큰은 Client가 이미 저장했다)
public struct LoggedInUser: Equatable, Sendable {
    public let userId: Int?
    public let nickname: String?
    /// 서버가 빈 토큰을 보냈는지 (레거시는 로그인 이슈로 기록한다)
    public let hasAccessToken: Bool
    /// 취향 평가를 마친 사용자인지 (소셜 로그인 분기)
    public let reviewCompleted: Bool?

    public init(userId: Int?, nickname: String?, hasAccessToken: Bool, reviewCompleted: Bool?) {
        self.userId = userId
        self.nickname = nickname
        self.hasAccessToken = hasAccessToken
        self.reviewCompleted = reviewCompleted
    }
}

/// 이메일 로그인 결과 (레거시 `EmailLoginViewModel.loginWithEmail`의 응답 코드 분기)
public enum EmailLoginResult: Equatable, Sendable {
    case success(LoggedInUser)
    /// 200인데 result가 없음 (화면은 그대로)
    case missingResult
    /// 110
    case invalidPasswordFormat
    /// 101·104·106
    case wrongCredentials
    /// 105
    case emptyPassword
    /// 112
    case accountNotFound
    /// 132
    case withdrawn
    /// 102
    case emptyEmail
    case unexpected(code: Int)
}

/// 이메일 회원가입 결과
public enum EmailSignupResult: Equatable, Sendable {
    /// 200. 토큰·사용자 정보는 Client가 저장했다
    case success
    /// 109
    case duplicatedEmail
    /// 그 밖의 코드 (레거시는 아무것도 하지 않는다)
    case unexpected(code: Int)
}

/// 인증번호 보내기 결과 (`api/auth/email/send`)
public enum SendCodeResult: Equatable, Sendable {
    case sent
    /// 112
    case accountNotFound
    /// 103
    case invalidEmail
    /// 102
    case emptyEmail
    /// 그 밖의 코드 (레거시는 버튼을 "전송중..."으로 둔 채 아무것도 하지 않는다)
    case unexpected(code: Int)
}

/// 인증번호 확인 결과 (`api/auth/email/verify`)
public enum VerifyCodeResult: Equatable, Sendable {
    /// 200. 이메일을 이 기기에 저장했다 (재설정이 읽는다)
    case verified
    /// 113
    case emptyCode
    /// 114
    case wrongCode
    /// 115
    case expired
    case unexpected(code: Int)
}

/// 로그인·로그아웃.
public protocol AuthClient: Sendable {
    /// `POST api/users/login`. 성공하면 토큰과 사용자 정보(닉네임·이메일·sns 없음·userId)를 이 기기에 저장한다
    func loginWithEmail(email: String, password: String) async throws(TransportError)
        -> EmailLoginResult
    /// 소셜 SDK가 준 토큰으로 서버에 로그인한다. 토큰 없이 보낸다
    func socialLogin(_ provider: SocialProvider, code: String) async throws(TransportError)
        -> SocialLoginResult
    /// 카카오톡(설치돼 있으면) 또는 카카오 계정으로 로그인해 access token을 받는다
    @MainActor func kakaoAccessToken() async throws(SocialSignInFailure) -> String
    /// 맨 위 화면에서 구글 로그인을 띄워 id token을 받는다
    @MainActor func googleIDToken() async throws(SocialSignInFailure) -> String
    /// 앱 시작 때 1회 (카카오 SDK 초기화)
    @MainActor func configureSDKs()
    /// 로그인 앱에서 돌아온 URL. 카카오, 구글 순서로 처리했으면 true
    @MainActor func handleOpenURL(_ url: URL) -> Bool
    /// 카카오톡 로그인 URL만 처리한다 (SwiftUI onOpenURL — 레거시 그대로)
    @MainActor func handleKakaoURL(_ url: URL) -> Bool
    /// 비밀번호 찾기: 인증번호를 이메일로 보낸다
    func sendVerificationCode(email: String) async throws(TransportError) -> SendCodeResult
    func verifyCode(email: String, code: String) async throws(TransportError) -> VerifyCodeResult
    /// 인증을 마친 이메일(이 기기에 저장된 값)의 비밀번호를 바꾼다. 성공이면 true
    func resetPassword(newPassword: String, confirmation: String) async throws(TransportError)
        -> Bool
    /// `POST api/users/signup`. 성공하면 토큰과 사용자 정보(닉네임·이메일·sns 없음·userId 없음)를 저장한다
    func signupWithEmail(email: String, password: String, agreedToTerms: Bool)
        async throws(TransportError) -> EmailSignupResult
    /// 서버 응답을 기다린 뒤, 결과와 무관하게 이 기기의 로그인 정보를 지운다 (이메일 변경 후).
    func logout() async
    /// 지우기 직전 토큰으로 서버에 알려 두고, 응답을 기다리지 않고 바로 지운다 (설정 → 로그아웃).
    func logoutImmediately() async
}
