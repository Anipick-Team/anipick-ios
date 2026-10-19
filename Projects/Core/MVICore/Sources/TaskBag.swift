import Foundation
import os

/// 진행 중인 작업 목록. `Store`의 격리 없는 `deinit`에서도 취소할 수 있게 잠금으로 보호한다.
final class TaskBag: Sendable {
    private struct Entry {
        let token: UUID
        let task: Task<Void, Never>
    }

    // AnyHashable은 Sendable이 아니지만 키는 모두 Sendable한 id에서 만든다.
    private let entries = OSAllocatedUnfairLock(uncheckedState: [AnyHashable: Entry]())

    var count: Int {
        return entries.withLockUnchecked { $0.count }
    }

    /// 같은 키의 작업이 있으면 취소하고 바꿔 넣는다.
    func insert(_ task: Task<Void, Never>, key: AnyHashable, token: UUID) {
        let previous = entries.withLockUnchecked {
            $0.updateValue(Entry(token: token, task: task), forKey: key)
        }
        previous?.task.cancel()
    }

    /// 끝난 작업을 뺀다. 같은 키로 이미 바뀌어 들어간 작업은 그대로 둔다.
    func remove(key: AnyHashable, token: UUID) {
        entries.withLockUnchecked { entries in
            if entries[key]?.token == token {
                entries[key] = nil
            }
        }
    }

    func cancelAll() {
        let tasks = entries.withLockUnchecked { entries in
            defer { entries = [:] }
            return entries.values.map(\.task)
        }
        for task in tasks {
            task.cancel()
        }
    }
}
