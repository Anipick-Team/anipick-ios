import Foundation
import Observation

/// 화면 하나의 상태와 그 변경 경로.
///
/// 설계: notes/2026-10-19-1-7-mvicore-design.md
@MainActor
@Observable
public final class Store<R: Reducer> {
    public private(set) var state: R.State

    @ObservationIgnored private let reducer: R
    @ObservationIgnored private let tasks = TaskBag()

    public init(initialState: R.State, reducer: R) {
        self.state = initialState
        self.reducer = reducer
    }

    deinit {
        tasks.cancelAll()
    }

    /// 리듀서를 동기적으로 실행해 `state`를 바꾸고, 돌려받은 작업을 시작한다.
    @discardableResult
    public func send(_ intent: R.Intent) -> EffectTask {
        return start(reducer.reduce(into: &state, intent: intent))
    }

    private func start(_ effect: Effect<R.Intent>) -> EffectTask {
        switch effect {
        case .none:
            return EffectTask(task: nil)
        case .run(let id, let operation):
            return EffectTask(task: run(id: id, operation: operation))
        case .merge(let effects):
            let tasks = effects.compactMap { start($0).task }
            guard !tasks.isEmpty else {
                return EffectTask(task: nil)
            }
            // 모두 끝날 때까지 기다리는 작업. 기다리는 쪽이 취소되면 모두 취소한다
            return EffectTask(
                task: Task {
                    await withTaskCancellationHandler {
                        for task in tasks {
                            await task.value
                        }
                    } onCancel: {
                        for task in tasks {
                            task.cancel()
                        }
                    }
                }
            )
        }
    }

    /// 진행 중인 작업 수 (테스트용)
    var runningTaskCount: Int {
        return tasks.count
    }

    private func run(
        id: (any Hashable & Sendable)?,
        operation: @escaping @Sendable () async -> R.Intent?
    ) -> Task<Void, Never> {
        let key = id.map { AnyHashable($0) } ?? AnyHashable(UUID())
        let token = UUID()
        let task = Task { [weak self, tasks] in
            defer { tasks.remove(key: key, token: token) }
            let result = await operation()
            guard !Task.isCancelled, let result, let self else {
                return
            }
            self.send(result)
        }
        tasks.insert(task, key: key, token: token)
        return task
    }
}
