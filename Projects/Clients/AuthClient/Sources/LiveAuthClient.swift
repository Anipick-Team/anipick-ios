import AuthClientInterface
import ClientCore
import Networking
import Storage

/// `api/users/*` (레거시 `AuthAPI`·`LogoutAPI`)
public struct LiveAuthClient: AuthClient {
    /// 레거시 `UserDefaultsManager`와 같은 키
    static let nicknameKey = PreferenceKey("nickname", defaultValue: "--")
    static let emailKey = PreferenceKey("email", defaultValue: "")
    static let snsKey = PreferenceKey("sns", defaultValue: "")
    static let userIdKey = PreferenceKey("userId", defaultValue: 0)

    private let client: HTTPClient
    private let accessToken: @Sendable () async -> String?
    private let onLoggedOut: @Sendable () async -> Void
    private let storeTokens: @Sendable (_ access: String, _ refresh: String) async -> Void
    private let preferences: Preferences
    let kakaoAppKey: String

    /// - Parameters:
    ///   - client: 인증 클라이언트 (`tokenProvider`가 있는 것)
    ///   - accessToken: 지금 토큰 (`logoutImmediately`가 정리 전에 읽는다)
    ///   - onLoggedOut: 이 기기의 로그인 정보 정리 (App: 사용자 정보 삭제 + `AuthSession.signOut(.userLogout)`)
    ///   - storeTokens: 로그인 토큰 저장 (App: `AuthSession.store`)
    public init(
        client: HTTPClient,
        accessToken: @escaping @Sendable () async -> String? = { nil },
        onLoggedOut: @escaping @Sendable () async -> Void,
        storeTokens: @escaping @Sendable (_ access: String, _ refresh: String) async -> Void = {
            _, _ in
        },
        preferences: Preferences = Preferences(),
        kakaoAppKey: String = ""
    ) {
        self.client = client
        self.accessToken = accessToken
        self.onLoggedOut = onLoggedOut
        self.storeTokens = storeTokens
        self.preferences = preferences
        self.kakaoAppKey = kakaoAppKey
    }

    public func socialLogin(
        _ provider: SocialProvider,
        code: String
    ) async throws(TransportError) -> SocialLoginResult {
        let response = try await client.send(Self.socialLoginEndpoint(provider, code: code))
        switch response.code {
        case 200:
            // 레거시: result가 없어도 빈 토큰·빈 닉네임을 저장한다
            let result = response.result
            let accessToken = result?.token?.accessToken ?? ""
            preferences.set(provider.rawValue, for: Self.snsKey)
            await storeTokens(accessToken, result?.token?.refreshToken ?? "")
            preferences.set(result?.nickname ?? "", for: Self.nicknameKey)
            if let userId = result?.userId {
                preferences.set(userId, for: Self.userIdKey)
            } else {
                preferences.removeValue(for: Self.userIdKey)
            }
            return .success(
                LoggedInUser(
                    userId: result?.userId, nickname: result?.nickname,
                    hasAccessToken: !accessToken.isEmpty, reviewCompleted: result?.reviewCompletedYn
                ))
        case 132:
            return .withdrawn
        case 133:
            return .existingAccount(.email)
        case 134:
            return .existingAccount(.kakao)
        case 135:
            return .existingAccount(.google)
        case 136:
            return .existingAccount(.apple)
        default:
            return .unexpected(code: response.code)
        }
    }

    /// 레거시 `AuthAPI.socialLogin`: `/oauth` 경로는 토큰 없는 세션으로 보낸다
    static func socialLoginEndpoint(_ provider: SocialProvider, code: String) -> Endpoint<
        LoginResult
    > {
        return Endpoint(
            method: .post,
            path: "api/oauth/\(provider.rawValue)/callback",
            body: .json(["platform": "ios", "code": code]),
            requiresAuth: false
        )
    }

    public func loginWithEmail(
        email: String,
        password: String
    ) async throws(TransportError) -> EmailLoginResult {
        let response = try await client.send(
            Self.emailLoginEndpoint(email: email, password: password))
        switch response.code {
        case 200:
            guard let result = response.result else {
                return .missingResult
            }
            // 레거시 순서: 토큰 → 닉네임 → 이메일 → sns(이메일 가입은 빈 값) → userId
            let accessToken = result.token?.accessToken ?? ""
            await storeTokens(accessToken, result.token?.refreshToken ?? "")
            preferences.set(result.nickname ?? "---", for: Self.nicknameKey)
            preferences.set(email, for: Self.emailKey)
            preferences.set("", for: Self.snsKey)
            if let userId = result.userId {
                preferences.set(userId, for: Self.userIdKey)
            } else {
                preferences.removeValue(for: Self.userIdKey)
            }
            return .success(
                LoggedInUser(
                    userId: result.userId, nickname: result.nickname,
                    hasAccessToken: !accessToken.isEmpty, reviewCompleted: result.reviewCompletedYn)
            )
        case 110:
            return .invalidPasswordFormat
        case 101, 104, 106:
            return .wrongCredentials
        case 105:
            return .emptyPassword
        case 112:
            return .accountNotFound
        case 132:
            return .withdrawn
        case 102:
            return .emptyEmail
        default:
            return .unexpected(code: response.code)
        }
    }

    public func signupWithEmail(
        email: String,
        password: String,
        agreedToTerms: Bool
    ) async throws(TransportError) -> EmailSignupResult {
        let response = try await client.send(
            Self.signupEndpoint(email: email, password: password, agreedToTerms: agreedToTerms))
        switch response.code {
        case 200:
            // 레거시: result가 없어도 빈 토큰과 "nickname - null"을 저장한다. 가입 응답에는 userId가 없다
            await storeTokens(
                response.result?.token?.accessToken ?? "",
                response.result?.token?.refreshToken ?? "")
            preferences.set(response.result?.nickname ?? "nickname - null", for: Self.nicknameKey)
            preferences.set(email, for: Self.emailKey)
            preferences.set("", for: Self.snsKey)
            preferences.removeValue(for: Self.userIdKey)
            return .success
        case 109:
            return .duplicatedEmail
        default:
            return .unexpected(code: response.code)
        }
    }

    public func sendVerificationCode(email: String) async throws(TransportError) -> SendCodeResult {
        let response = try await client.send(
            Endpoint<EmptyResult>(
                method: .post, path: "api/auth/email/send", body: .json(["email": email]),
                requiresAuth: false))
        switch response.code {
        case 200:
            return .sent
        case 112:
            return .accountNotFound
        case 103:
            return .invalidEmail
        case 102:
            return .emptyEmail
        default:
            return .unexpected(code: response.code)
        }
    }

    public func verifyCode(email: String, code: String) async throws(TransportError)
        -> VerifyCodeResult
    {
        let response = try await client.send(
            Endpoint<EmptyResult>(
                method: .post, path: "api/auth/email/verify",
                body: .json(["email": email, "code": code]), requiresAuth: false))
        switch response.code {
        case 200:
            preferences.set(email, for: Self.emailKey)
            return .verified
        case 113:
            return .emptyCode
        case 114:
            return .wrongCode
        case 115:
            return .expired
        default:
            return .unexpected(code: response.code)
        }
    }

    public func resetPassword(newPassword: String, confirmation: String)
        async throws(TransportError)
        -> Bool
    {
        let response = try await client.send(
            Endpoint<EmptyResult>(
                method: .patch, path: "api/auth/password/reset",
                body: .json([
                    "email": preferences.value(for: Self.emailKey), "newPassword": newPassword,
                    "checkNewPassword": confirmation,
                ]),
                requiresAuth: false))
        return response.code == 200
    }

    /// 레거시는 인증 세션으로 보내 빈(또는 이전) 토큰이 붙었다. 가입에는 토큰이 필요 없어 붙이지 않는다
    static func signupEndpoint(email: String, password: String, agreedToTerms: Bool) -> Endpoint<
        LoginResult
    > {
        return Endpoint(
            method: .post,
            path: "api/users/signup",
            body: .json(
                SignupBody(email: email, password: password, termsAndConditions: agreedToTerms)),
            requiresAuth: false
        )
    }

    /// 로그인은 토큰 없이 보낸다 — 이전 세션의 낡은 토큰이 붙어 실패하던 문제 (레거시 NetworkManager plainSession)
    static func emailLoginEndpoint(email: String, password: String) -> Endpoint<LoginResult> {
        return Endpoint(
            method: .post,
            path: "api/users/login",
            body: .json(["email": email, "password": password]),
            requiresAuth: false
        )
    }

    public func logout() async {
        // 레거시: 응답이 성공이든 실패든 로그아웃한다 (EditEmailViewModel.swift:44-63)
        _ = try? await client.send(Self.logoutEndpoint)
        await onLoggedOut()
    }

    public func logoutImmediately() async {
        // HTTPClient는 보내는 시점에 토큰을 읽으므로, 정리보다 먼저 읽어 헤더에 직접 넣는다 (1-6 AC10)
        let endpoint = Self.logoutEndpoint(token: await accessToken() ?? "")
        let client = client
        Task {
            _ = try? await client.send(endpoint)
        }
        await onLoggedOut()
    }

    /// 토큰을 헤더에 직접 넣은 요청. 정리 뒤에 나가도 토큰이 실린다
    static func logoutEndpoint(token: String) -> Endpoint<EmptyResult> {
        return Endpoint(
            method: .post,
            path: "api/users/logout",
            headers: ["Authorization": "Bearer \(token)"],
            requiresAuth: false
        )
    }

    static let logoutEndpoint = Endpoint<EmptyResult>(
        method: .post,
        path: "api/users/logout",
        requiresAuth: true
    )
}

/// 레거시 `LoginResult`
struct LoginResult: Decodable, Sendable {
    struct Token: Decodable, Sendable {
        let accessToken: String
        let refreshToken: String
    }

    let reviewCompletedYn: Bool?
    let userId: Int?
    let nickname: String?
    let token: Token?
}

struct SignupBody: Encodable, Sendable {
    let email: String
    let password: String
    let termsAndConditions: Bool
}
