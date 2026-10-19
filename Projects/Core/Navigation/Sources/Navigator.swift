/// Feature가 화면 이동을 요청하는 경로. 경로를 소유한 App이 구현한다.
///
/// Route는 각 Feature의 Interface 모듈(기본 격리 nonisolated)에 둔다. 기본 격리가 MainActor인
/// 모듈에서 선언한 Route는 `Hashable` 적합성이 MainActor로 격리되어 여기에 넘길 수 없다.
///
/// 리듀서는 `Effect` 안에서 부른다 — `Sendable`이라 `@Sendable` 클로저에 담을 수 있다.
/// ```swift
/// return .run { [navigator] in
///     await navigator.push(DetailRoute(animeId: id))
///     return nil
/// }
/// ```
///
/// 설계: notes/2026-10-19-1-8-navigation-design.md
@MainActor
public protocol Navigator: AnyObject, Sendable {
    func push(_ route: some Hashable & Sendable)
    func pop()
    func popToRoot()
    /// 다른 Feature 화면을 모달로 띄운다. 표시 형태는 App이 정한다.
    func present(_ route: some Hashable & Sendable)
    func dismiss()
}
