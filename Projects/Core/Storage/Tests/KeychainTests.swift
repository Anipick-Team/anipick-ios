import Foundation
import Security
import Testing

import Storage

@Suite("Keychain")
final class KeychainTests {
    // 테스트마다 다른 service를 써서 서로의 항목을 보지 않게 한다.
    private let keychain = Keychain(service: "com.moana.StorageTests.\(UUID().uuidString)")

    deinit {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychain.service,
        ]
        SecItemDelete(query as CFDictionary)
    }

    @Test("저장한 적 없는 키는 nil을 돌려준다")
    func missingKeyReturnsNil() throws {
        #expect(try keychain.string(for: "accessToken") == nil)
    }

    @Test("저장한 문자열을 그대로 읽는다")
    func storesAndReadsString() throws {
        try keychain.setString("token-1", for: "accessToken")

        #expect(try keychain.string(for: "accessToken") == "token-1")
    }

    @Test("같은 키에 다시 저장하면 덮어쓴다")
    func overwritesExistingValue() throws {
        try keychain.setString("token-1", for: "accessToken")
        try keychain.setString("token-2", for: "accessToken")

        #expect(try keychain.string(for: "accessToken") == "token-2")
    }

    @Test("삭제하면 nil을 돌려주고, 없는 키를 삭제해도 실패하지 않는다")
    func removesValue() throws {
        try keychain.setString("token-1", for: "accessToken")

        try keychain.removeValue(for: "accessToken")
        try keychain.removeValue(for: "accessToken")

        #expect(try keychain.string(for: "accessToken") == nil)
    }

    @Test("키가 다르면 서로의 값을 보지 않는다")
    func isolatesKeys() throws {
        try keychain.setString("access", for: "accessToken")
        try keychain.setString("refresh", for: "refreshToken")

        #expect(try keychain.string(for: "accessToken") == "access")
        #expect(try keychain.string(for: "refreshToken") == "refresh")
    }

    @Test("service가 다르면 서로의 값을 보지 않는다")
    func isolatesServices() throws {
        let other = Keychain(service: "com.moana.StorageTests.\(UUID().uuidString)")
        defer { try? other.removeValue(for: "accessToken") }

        try keychain.setString("mine", for: "accessToken")

        #expect(try other.string(for: "accessToken") == nil)
    }

    @Test("항목을 AfterFirstUnlockThisDeviceOnly 접근성으로 저장한다")
    func storesWithAccessibility() throws {
        try keychain.setString("token-1", for: "accessToken")
        try keychain.setString("token-2", for: "accessToken")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychain.service,
            kSecAttrAccount as String: "accessToken",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let attributes = try #require(result as? [String: Any])

        #expect(status == errSecSuccess)
        #expect(
            attributes[kSecAttrAccessible as String] as? String
                == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        )
    }
}
