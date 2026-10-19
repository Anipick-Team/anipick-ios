import ClientCore
import Networking
import Storage
import UserClientInterface

/// `api/setting/*` (레거시 `SettingAPI`).
public struct LiveUserClient: UserClient {
    /// 레거시 `UserDefaultsManager`와 같은 키
    static let nicknameKey = PreferenceKey("nickname", defaultValue: "--")

    private let client: HTTPClient
    private let preferences: Preferences

    /// - Parameter client: 인증 클라이언트 (`tokenProvider`가 있는 것)
    public init(client: HTTPClient, preferences: Preferences = Preferences()) {
        self.client = client
        self.preferences = preferences
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
