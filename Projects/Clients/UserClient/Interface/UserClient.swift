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
    func editPassword(current: String, new: String, confirmation: String)
        async throws(EditPasswordError)
    /// 가입한 SNS (`KAKAO`·`GOOGLE`·`APPLE`). 이메일 가입이면 `""`
    func cachedSNSAccount() -> String
    /// 성공하면 저장된 이메일도 바꾼다.
    func editEmail(newEmail: String, password: String) async throws(EditEmailError)
}

public enum EditEmailError: Error, Equatable, Sendable {
    /// 이메일을 입력하지 않음
    case emptyEmail
    /// 이메일 형식이 아님
    case invalidEmailFormat
    /// 비밀번호가 틀림
    case passwordMismatch
    /// 이미 쓰는 이메일
    case duplicatedEmail
    /// 서버가 알 수 없는 결과 코드를 보냈다
    case unexpectedResponse
    case transport(TransportError)
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

public enum EditPasswordError: Error, Equatable, Sendable {
    /// 현재 비밀번호가 틀림
    case currentPasswordMismatch
    /// 새 비밀번호와 확인이 다름
    case confirmationMismatch
    /// 서버가 알 수 없는 결과 코드를 보냈다
    case unexpectedResponse
    case transport(TransportError)
}

public enum WithdrawalError: Error, Equatable, Sendable {
    /// 서버가 탈퇴를 처리하지 않았다 (200이 아닌 결과 코드)
    case rejected
    case transport(TransportError)
}
