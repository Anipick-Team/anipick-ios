import ClientCore

/// 내 계정 정보 (설정 화면).
public protocol UserClient: Sendable {
    /// 이 기기에 저장된 닉네임. 없으면 `"--"`
    func cachedNickname() -> String
    /// 성공하면 저장된 닉네임도 바꾼다.
    func editNickname(_ nickname: String) async throws(EditNicknameError)
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
