/// 상태 변경 규칙. Intent를 받아 State를 바꾸고, 필요한 비동기 작업을 `Effect`로 돌려준다.
///
/// 순수 함수로 유지한다 — 네트워크·저장소 접근은 `Effect` 안에서만 한다 (tech-stack B1).
/// Feature 모듈(기본 격리 MainActor)에서 선언하면 MainActor로 격리된 적합성이 되어,
/// `Store`(MainActor)에서 동기적으로 실행된다.
public protocol Reducer {
    associatedtype State
    associatedtype Intent: Sendable

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent>
}
