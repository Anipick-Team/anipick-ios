/// Client Interface들이 공통으로 던지는 전송 계층 에러.
///
/// Client 프로토콜은 `throws(TransportError)` 또는 이 에러를 감싼 도메인 에러를 던진다.
/// 서버 업무 코드(HTTP 200 본문의 `code`)와 `URLError`는 Client Live 안에서 이 타입이나
/// 도메인 에러로 바꾸고 밖으로 노출하지 않는다 (tech-stack "Client 에러 모델").
public enum TransportError: Error, Equatable, Sendable {
    /// 네트워크에 연결되어 있지 않음
    case offline
    /// 요청 시간 초과
    case timeout
    /// 토큰 갱신에 실패해 세션이 끝남. Session이 로그인 화면으로 전환하므로 Feature는 알릴 필요가 없다.
    case sessionExpired
    /// 2xx가 아닌 HTTP 상태 코드
    case server(status: Int)
    /// 응답을 앱 모델로 바꾸지 못함
    case decoding
    /// 요청이 취소됨 (Effect 취소, 화면 이탈). 사용자에게 알리지 않는다.
    case cancelled
    /// 그 밖의 실패
    case unknown
}
