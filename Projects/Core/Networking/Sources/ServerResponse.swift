import ClientCore

/// 서버 공통 응답 `{ code, value, errorValue, result }`.
///
/// 서버는 업무 에러를 HTTP 200 + `code != 200`으로 보낸다. `HTTPClient`는 업무 코드를 판단하지 않고,
/// 각 Client Live가 코드를 도메인 에러로 바꾼다.
public struct ServerResponse<Result: Sendable>: Sendable {
    public let code: Int
    public let value: String
    /// 업무 에러일 때 사용자에게 보여 줄 문구
    public let errorValue: String?
    public let result: Result?

    public init(code: Int, value: String, errorValue: String?, result: Result?) {
        self.code = code
        self.value = value
        self.errorValue = errorValue
        self.result = result
    }

    /// 결과가 없으면 응답 형식이 기대와 다른 것으로 본다.
    public func requireResult() throws(TransportError) -> Result {
        guard let result else {
            throw .decoding
        }
        return result
    }
}

/// 결과 본문이 없는 요청용 (레거시 `BaseResponse` 대응)
public struct EmptyResult: Decodable, Sendable {
    public init() {}
}

struct ServerEnvelope<Result: Decodable>: Decodable {
    let code: Int
    let value: String?
    let errorValue: String?
    let result: Result?
}

/// 토큰 만료 판정용으로 `code`만 읽는다.
struct ServerCode: Decodable {
    static let tokenExpired = 119

    let code: Int
}
