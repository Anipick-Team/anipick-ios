import ClientCore

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

/// 로그인·로그아웃.
public protocol AuthClient: Sendable {
    /// `POST api/users/login`. 성공하면 토큰과 사용자 정보(닉네임·이메일·sns 없음·userId)를 이 기기에 저장한다
    func loginWithEmail(email: String, password: String) async throws(TransportError)
        -> EmailLoginResult
    /// 서버 응답을 기다린 뒤, 결과와 무관하게 이 기기의 로그인 정보를 지운다 (이메일 변경 후).
    func logout() async
    /// 지우기 직전 토큰으로 서버에 알려 두고, 응답을 기다리지 않고 바로 지운다 (설정 → 로그아웃).
    func logoutImmediately() async
}
