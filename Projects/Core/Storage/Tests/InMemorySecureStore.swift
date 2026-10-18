import Foundation
import Security
import os

import Storage

/// 실패를 주입할 수 있는 메모리 `SecureStore`. 실패는 Keychain 잠금 상태 코드로 낸다.
final class InMemorySecureStore: SecureStore {
    struct State: Sendable {
        var items: [String: Data] = [:]
        /// 쓰기가 실패하는 키
        var failingWrites: Set<String> = []
        /// 읽기가 실패하는 키
        var failingReads: Set<String> = []
        /// 삭제가 실패하는 키
        var failingDeletes: Set<String> = []
        /// 값이 있으면 저장된 것과 다른 값을 돌려주는 키
        var corruptedReads: Set<String> = []
        var writeCount = 0
    }

    static let lockedError = KeychainError.unexpectedStatus(errSecInteractionNotAllowed)

    private let state = OSAllocatedUnfairLock(initialState: State())

    func update(_ body: @Sendable (inout State) -> Void) {
        state.withLock(body)
    }

    /// 실패 주입과 무관하게 저장된 값을 본다 (단언용).
    func storedString(for key: String) -> String? {
        let data = state.withLock { $0.items[key] }
        return data.map { String(decoding: $0, as: UTF8.self) }
    }

    var isEmpty: Bool {
        return state.withLock { $0.items.isEmpty }
    }

    var writeCount: Int {
        return state.withLock { $0.writeCount }
    }

    func data(for key: String) throws(KeychainError) -> Data? {
        let snapshot = state.withLock { $0 }
        if snapshot.failingReads.contains(key) {
            throw Self.lockedError
        }
        guard let data = snapshot.items[key] else {
            return nil
        }
        if snapshot.corruptedReads.contains(key) {
            return Data("corrupted".utf8)
        }
        return data
    }

    func setData(_ data: Data, for key: String) throws(KeychainError) {
        let failed = state.withLock { state -> Bool in
            state.writeCount += 1
            guard !state.failingWrites.contains(key) else {
                return true
            }
            state.items[key] = data
            return false
        }
        if failed {
            throw Self.lockedError
        }
    }

    func removeValue(for key: String) throws(KeychainError) {
        let failed = state.withLock { state -> Bool in
            guard !state.failingDeletes.contains(key) else {
                return true
            }
            state.items[key] = nil
            return false
        }
        if failed {
            throw Self.lockedError
        }
    }
}
