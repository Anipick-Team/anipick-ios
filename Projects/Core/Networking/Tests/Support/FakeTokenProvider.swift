import ClientCore
import Networking

actor FakeTokenProvider: TokenProviding {
    private var token: String?
    private let refreshedToken: String?
    private let refreshError: TransportError?
    private(set) var refreshCount = 0

    /// - Parameters:
    ///   - refreshedToken: 갱신에 성공하면 바뀔 토큰
    ///   - refreshError: 갱신이 실패할 때 던질 에러
    init(token: String?, refreshedToken: String? = nil, refreshError: TransportError? = nil) {
        self.token = token
        self.refreshedToken = refreshedToken
        self.refreshError = refreshError
    }

    func accessToken() -> String? {
        return token
    }

    func refreshAccessToken() throws(TransportError) {
        refreshCount += 1
        if let refreshError {
            throw refreshError
        }
        token = refreshedToken
    }
}
