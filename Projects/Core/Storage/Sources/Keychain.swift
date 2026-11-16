import Foundation
import Security

/// Keychain Services의 generic password 항목을 키-값으로 다룬다.
/// `service`가 같은 항목끼리 하나의 저장소를 이룬다.
public struct Keychain: SecureStore {
    public enum Accessibility: Sendable {
        /// 재부팅 후 첫 잠금 해제 이후 접근 가능(백그라운드 토큰 갱신 가능), 백업 복원 시 다른 기기로 옮겨지지 않음.
        /// 토큰 저장 기본값 (이관 프로그램 Q1).
        case afterFirstUnlockThisDeviceOnly

        var attribute: CFString {
            switch self {
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }

    public let service: String
    public let accessibility: Accessibility

    public init(service: String, accessibility: Accessibility = .afterFirstUnlockThisDeviceOnly) {
        self.service = service
        self.accessibility = accessibility
    }

    public func data(for key: String) throws(KeychainError) -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw .invalidData
            }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw .unexpectedStatus(status)
        }
    }

    public func setData(_ data: Data, for key: String) throws(KeychainError) {
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility.attribute,
        ]
        let updateStatus = SecItemUpdate(
            baseQuery(for: key) as CFDictionary,
            attributes as CFDictionary
        )
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            let query = baseQuery(for: key).merging(attributes) { _, new in new }
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw .unexpectedStatus(addStatus)
            }
        default:
            throw .unexpectedStatus(updateStatus)
        }
    }

    public func removeValue(for key: String) throws(KeychainError) {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw .unexpectedStatus(status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
