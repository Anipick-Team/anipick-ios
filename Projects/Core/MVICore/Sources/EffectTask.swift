/// `Store.send`가 시작한 작업.
public struct EffectTask: Sendable {
    let task: Task<Void, Never>?

    /// 작업과 그 결과 Intent의 반영이 끝날 때까지 기다린다.
    /// 결과 Intent가 다시 시작한 작업은 기다리지 않는다.
    ///
    /// 기다리는 쪽이 취소되면 작업도 취소된다 — View의 `.task`에서 기다리면 화면이 사라질 때 함께 취소된다.
    /// ```swift
    /// .task { await store.send(.onAppear).finish() }
    /// ```
    public func finish() async {
        guard let task else {
            return
        }
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
