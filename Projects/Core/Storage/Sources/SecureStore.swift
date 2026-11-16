import Foundation

public enum KeychainError: Error, Equatable, Sendable {
    /// Security 프레임워크가 돌려준 실패 코드 (`errSecSuccess`·`errSecItemNotFound` 외)
    case unexpectedStatus(OSStatus)
    /// 저장된 값이 기대한 형식(UTF-8 문자열 등)이 아님
    case invalidData
}

/// 민감 정보(토큰 등) 저장소. 토큰 이관(1-2)에서 실패 경로를 시험할 수 있도록 프로토콜로 둔다.
public protocol SecureStore: Sendable {
    /// 값이 없으면 `nil`
    func data(for key: String) throws(KeychainError) -> Data?
    /// 같은 키가 있으면 덮어쓴다.
    func setData(_ data: Data, for key: String) throws(KeychainError)
    /// 값이 없어도 실패하지 않는다.
    func removeValue(for key: String) throws(KeychainError)
}

extension SecureStore {
    public func string(for key: String) throws(KeychainError) -> String? {
        guard let data = try data(for: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw .invalidData
        }
        return string
    }

    public func setString(_ string: String, for key: String) throws(KeychainError) {
        try setData(Data(string.utf8), for: key)
    }
}
