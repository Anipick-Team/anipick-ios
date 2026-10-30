public enum SignOutReason: Sendable, Equatable {
    /// 사용자가 로그아웃
    case userLogout
    /// 탈퇴
    case withdrawal
    /// 서버가 토큰 갱신을 거절
    case expired
}

/// Session이 App에 알리는 상태 변화.
/// 로그인 성공은 알리지 않는다 — 온보딩을 마친 뒤의 루트 전환은 App이 정한다.
public enum SessionEvent: Sendable, Equatable {
    case signedOut(SignOutReason)
}
