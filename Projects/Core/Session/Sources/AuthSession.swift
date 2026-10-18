import ClientCore
import Networking
import Storage

/// 인증 토큰과 갱신 로직의 단일 소유자.
///
/// - 동시에 여러 요청이 토큰 만료를 만나도 서버 갱신 요청은 1회만 보낸다.
/// - 서버가 갱신을 거절하면 토큰을 지우고 `.signedOut(.expired)`를 알린다.
///   오프라인·타임아웃·취소는 토큰을 유지한다 (일시 오류로 로그아웃시키지 않는다).
///
/// 설계: notes/2026-10-18-1-5-session-design.md
public actor AuthSession: TokenProviding {
    /// App의 `SessionState` 하나가 구독한다. 구독 전 이벤트는 버퍼에 남는다.
    public nonisolated let events: AsyncStream<SessionEvent>

    private let continuation: AsyncStream<SessionEvent>.Continuation
    private let tokenStore: AuthTokenStore
    private let refresher: any TokenRefreshing
    private var refreshTask: Task<Result<Void, TransportError>, Never>?

    public init(tokenStore: AuthTokenStore, refresher: any TokenRefreshing) {
        (events, continuation) = AsyncStream.makeStream(of: SessionEvent.self)
        self.tokenStore = tokenStore
        self.refresher = refresher
    }

    /// access 토큰이 있는지 (앱 시작 시 루트 결정용)
    public var hasTokens: Bool {
        return !tokenStore.accessToken.isEmpty
    }

    public func accessToken() -> String? {
        let token = tokenStore.accessToken
        return token.isEmpty ? nil : token
    }

    public func refreshAccessToken() async throws(TransportError) {
        if let refreshTask {
            try await refreshTask.value.get()
            return
        }
        let task = Task { await performRefresh() }
        refreshTask = task
        let result = await task.value
        refreshTask = nil
        try result.get()
    }

    /// 로그인·가입에 성공했을 때. 이벤트는 내보내지 않는다.
    public func store(_ tokens: TokenPair) {
        tokenStore.setAccessToken(tokens.accessToken)
        tokenStore.setRefreshToken(tokens.refreshToken)
    }

    public func signOut(_ reason: SignOutReason) {
        clearTokens()
        continuation.yield(.signedOut(reason))
    }

    // MARK: - Private

    private func performRefresh() async -> Result<Void, TransportError> {
        let refreshToken = tokenStore.refreshToken
        guard !refreshToken.isEmpty else {
            expire()
            return .failure(.sessionExpired)
        }
        do throws(TransportError) {
            guard let tokens = try await refresher.refresh(refreshToken: refreshToken) else {
                expire()
                return .failure(.sessionExpired)
            }
            store(tokens)
            return .success(())
        } catch {
            switch error {
            case .offline, .timeout, .cancelled:
                return .failure(error)
            default:
                expire()
                return .failure(.sessionExpired)
            }
        }
    }

    /// 지울 토큰이 있었을 때만 알린다 — 이미 만료된 뒤 들어온 요청이 이벤트를 반복하지 않게.
    private func expire() {
        let hadTokens = !tokenStore.accessToken.isEmpty || !tokenStore.refreshToken.isEmpty
        clearTokens()
        if hadTokens {
            continuation.yield(.signedOut(.expired))
        }
    }

    private func clearTokens() {
        tokenStore.setAccessToken("")
        tokenStore.setRefreshToken("")
    }
}
