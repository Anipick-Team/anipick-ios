import ClientCore
import Networking
import Storage
import UserClientInterface

/// `api/setting/*` (레거시 `SettingAPI`).
public struct LiveUserClient: UserClient {
    /// 레거시 `UserDefaultsManager`와 같은 키
    static let nicknameKey = PreferenceKey("nickname", defaultValue: "--")
    static let emailKey = PreferenceKey("email", defaultValue: "")

    private let client: HTTPClient
    private let preferences: Preferences
    private let onWithdrawn: @Sendable () async -> Void

    /// - Parameters:
    ///   - client: 인증 클라이언트 (`tokenProvider`가 있는 것)
    ///   - onWithdrawn: 탈퇴 성공 후 로그아웃 처리 (App: `AuthSession.signOut(.withdrawal)`)
    public init(
        client: HTTPClient,
        preferences: Preferences = Preferences(),
        onWithdrawn: @escaping @Sendable () async -> Void = {}
    ) {
        self.client = client
        self.preferences = preferences
        self.onWithdrawn = onWithdrawn
    }

    public func cachedNickname() -> String {
        return preferences.value(for: Self.nicknameKey)
    }

    public func editNickname(_ nickname: String) async throws(EditNicknameError) {
        let response: ServerResponse<EmptyResult>
        do {
            response = try await client.send(Self.editNicknameEndpoint(nickname))
        } catch {
            throw .transport(error)
        }
        try Self.editNicknameResult(code: response.code).get()
        preferences.set(nickname, for: Self.nicknameKey)
    }

    public func cachedEmail() -> String {
        return preferences.value(for: Self.emailKey)
    }

    public func withdraw() async throws(WithdrawalError) {
        let response: ServerResponse<EmptyResult>
        do {
            response = try await client.send(Self.withdrawalEndpoint)
        } catch {
            throw .transport(error)
        }
        guard response.code == 200 else {
            throw .rejected
        }
        // 레거시 순서: 닉네임 비우기 → 로그아웃 (WithdrawalViewModel.swift:29-36)
        preferences.set("", for: Self.nicknameKey)
        await onWithdrawn()
    }

    public func editPassword(
        current: String,
        new: String,
        confirmation: String
    ) async throws(EditPasswordError) {
        let response: ServerResponse<EmptyResult>
        do {
            response = try await client.send(
                Self.editPasswordEndpoint(current: current, new: new, confirmation: confirmation)
            )
        } catch {
            throw .transport(error)
        }
        try Self.editPasswordResult(code: response.code).get()
    }

    static func editPasswordEndpoint(
        current: String,
        new: String,
        confirmation: String
    ) -> Endpoint<EmptyResult> {
        return Endpoint(
            method: .patch,
            path: "api/setting/password",
            body: .json([
                "currentPassword": current,
                "newPassword": new,
                "confirmNewPassword": confirmation,
            ]),
            requiresAuth: true
        )
    }

    /// 레거시 `EditPasswordViewModel.swift:84-93`
    static func editPasswordResult(code: Int) -> Result<Void, EditPasswordError> {
        switch code {
        case 200:
            return .success(())
        case 107:
            return .failure(.currentPasswordMismatch)
        case 108:
            return .failure(.confirmationMismatch)
        default:
            return .failure(.unexpectedResponse)
        }
    }

    static let withdrawalEndpoint = Endpoint<EmptyResult>(
        method: .patch,
        path: "api/setting/withdrawal",
        requiresAuth: true
    )

    static func editNicknameEndpoint(_ nickname: String) -> Endpoint<EmptyResult> {
        return Endpoint(
            method: .patch,
            path: "api/setting/nickname",
            body: .json(["nickname": nickname]),
            requiresAuth: true
        )
    }

    /// 서버 결과 코드 → 의미 (레거시 `EditNicknameViewModel.swift:41-58`)
    static func editNicknameResult(code: Int) -> Result<Void, EditNicknameError> {
        switch code {
        case 200:
            return .success(())
        case 117:
            return .failure(.duplicated)
        case 116:
            return .failure(.invalidFormat)
        case 118:
            return .failure(.empty)
        default:
            return .failure(.unexpectedResponse)
        }
    }
}
