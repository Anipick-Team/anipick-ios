/// 리듀서가 돌려주는 비동기 작업.
public enum Effect<Intent: Sendable>: Sendable {
    case none
    /// 작업이 돌려준 Intent는 `Store`가 다시 send한다 (`nil`이면 아무것도 하지 않는다).
    ///
    /// - 같은 `id`의 새 작업이 오면 진행 중인 작업을 취소한다 (검색어 연속 입력 등).
    /// - 취소된 작업의 결과는 반영하지 않는다.
    case run(id: (any Hashable & Sendable)? = nil, operation: @Sendable () async -> Intent?)
}
