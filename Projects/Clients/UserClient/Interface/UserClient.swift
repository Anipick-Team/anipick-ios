import ClientCore

/// 내 계정 정보 (설정 화면).
public protocol UserClient: Sendable {
    /// 이 기기에 저장된 닉네임. 없으면 `"--"`
    func cachedNickname() -> String
    /// 성공하면 저장된 닉네임도 바꾼다.
    func editNickname(_ nickname: String) async throws(EditNicknameError)
    /// 이 기기에 저장된 이메일. 없으면 `""`
    func cachedEmail() -> String
    /// 회원 탈퇴. 성공하면 저장된 닉네임을 비우고 로그아웃 처리(App이 주입)를 한다.
    func withdraw() async throws(WithdrawalError)
}

public enum EditNicknameError: Error, Equatable, Sendable {
    /// 이미 사용 중인 닉네임
    case duplicated
    /// 길이·문자 조합 규칙 위반
    case invalidFormat
    /// 빈 닉네임
    case empty
    /// 서버가 알 수 없는 결과 코드를 보냈다
    case unexpectedResponse
    case transport(TransportError)
}

public enum WithdrawalError: Error, Equatable, Sendable {
    /// 서버가 탈퇴를 처리하지 않았다 (200이 아닌 결과 코드)
    case rejected
    case transport(TransportError)
}
