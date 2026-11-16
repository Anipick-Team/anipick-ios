/// 조건이 맞을 때까지 기다린다 (기한 2초). Store의 `finish()`는 이어지는 Effect를 기다리지 않는다.
public func waitUntil(_ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + .seconds(2)
    while !condition() {
        guard ContinuousClock.now < deadline else {
            return false
        }
        try? await Task.sleep(for: .milliseconds(5))
    }
    return true
}
