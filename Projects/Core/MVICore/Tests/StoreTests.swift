import Observation
import Testing
import os

@testable import MVICore

/// 작업 시작·취소를 기록한다. 시간을 정해 기다리지 않고 조건이 맞을 때까지 기다린다 (기한 있음).
actor Recorder {
    private(set) var started: [String] = []
    private(set) var cancelled: [String] = []

    func start(_ value: String) {
        started.append(value)
    }

    func cancel(_ value: String) {
        cancelled.append(value)
    }

    struct Snapshot: Sendable {
        let started: [String]
        let cancelled: [String]
    }

    func waitUntil(
        timeout: Duration = .seconds(2),
        _ condition: @Sendable (Snapshot) -> Bool
    ) async -> Bool {
        let deadline = ContinuousClock.now + timeout
        while !condition(Snapshot(started: started, cancelled: cancelled)) {
            guard ContinuousClock.now < deadline else {
                return false
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return true
    }
}

struct TestReducer: Reducer {
    let recorder: Recorder

    struct State {
        var count = 0
        var log: [String] = []
    }

    enum Intent: Sendable {
        case increment
        /// `delay` 동안 기다린 뒤 `.loaded(value)`를 돌려준다. 취소되면 기록하고, 그래도 결과는 돌려준다.
        case load(id: String?, value: String, delay: Duration)
        case loaded(String)
        case loadNothing
    }

    func reduce(into state: inout State, intent: Intent) -> Effect<Intent> {
        switch intent {
        case .increment:
            state.count += 1
            return .none
        case .load(let id, let value, let delay):
            return .run(id: id) { [recorder] in
                await recorder.start(value)
                do {
                    try await Task.sleep(for: delay)
                } catch {
                    await recorder.cancel(value)
                }
                return .loaded(value)
            }
        case .loaded(let value):
            state.log.append(value)
            return .none
        case .loadNothing:
            return .run { nil }
        }
    }
}

@MainActor
@Suite("Store", .timeLimit(.minutes(1)))
struct StoreTests {
    private let recorder = Recorder()

    private func makeStore() -> Store<TestReducer> {
        return Store(initialState: TestReducer.State(), reducer: TestReducer(recorder: recorder))
    }

    @Test("send는 리듀서를 동기적으로 실행해 state를 바꾸고, 작업이 없으면 finish가 바로 끝난다")
    func changesStateSynchronously() async {
        let store = makeStore()

        let effect = store.send(.increment)

        #expect(store.state.count == 1)
        await effect.finish()
        #expect(store.runningTaskCount == 0)
    }

    @Test("작업의 결과 Intent를 다시 send하고, 끝난 작업은 목록에서 뺀다")
    func reinjectsResultIntent() async {
        let store = makeStore()

        await store.send(.load(id: nil, value: "A", delay: .zero)).finish()

        #expect(store.state.log == ["A"])
        #expect(store.runningTaskCount == 0)
    }

    @Test("작업이 nil을 돌려주면 아무것도 하지 않는다")
    func ignoresNilResult() async {
        let store = makeStore()

        await store.send(.loadNothing).finish()

        #expect(store.state.log.isEmpty)
        #expect(store.state.count == 0)
        #expect(store.runningTaskCount == 0)
    }

    @Test("같은 id의 새 작업은 이전 작업을 취소하고, 취소된 작업의 결과는 반영하지 않는다")
    func cancelsPreviousTaskWithSameID() async {
        let store = makeStore()

        let first = store.send(.load(id: "search", value: "A", delay: .seconds(10)))
        let second = store.send(.load(id: "search", value: "B", delay: .zero))
        await second.finish()
        await first.finish()

        #expect(store.state.log == ["B"])
        #expect(await recorder.cancelled == ["A"])
        #expect(store.runningTaskCount == 0)
    }

    @Test("id가 다르거나 없는 작업은 서로 취소하지 않는다")
    func keepsTasksWithDifferentIDs() async {
        let store = makeStore()

        let effects = [
            store.send(.load(id: "x", value: "A", delay: .milliseconds(20))),
            store.send(.load(id: "y", value: "B", delay: .milliseconds(20))),
            store.send(.load(id: nil, value: "C", delay: .milliseconds(20))),
            store.send(.load(id: nil, value: "D", delay: .milliseconds(20))),
        ]
        for effect in effects {
            await effect.finish()
        }

        #expect(store.state.log.sorted() == ["A", "B", "C", "D"])
        #expect(await recorder.cancelled.isEmpty)
    }

    @Test("Store가 해제되면 진행 중인 작업을 모두 취소한다")
    func cancelsAllTasksOnDeinit() async {
        weak var weakStore: Store<TestReducer>?
        do {
            let store = makeStore()
            weakStore = store
            store.send(.load(id: "search", value: "A", delay: .seconds(10)))
            store.send(.load(id: nil, value: "B", delay: .seconds(10)))
            #expect(await recorder.waitUntil { $0.started.count == 2 })
        }

        #expect(weakStore == nil)
        #expect(await recorder.waitUntil { $0.cancelled.count == 2 })
        #expect(await recorder.cancelled.sorted() == ["A", "B"])
    }

    @Test("finish를 기다리던 쪽이 취소되면 작업도 취소된다 (View .task)")
    func cancelsTaskWhenFinishIsCancelled() async {
        let store = makeStore()
        let effect = store.send(.load(id: nil, value: "A", delay: .seconds(10)))
        let viewTask = Task { await effect.finish() }
        #expect(await recorder.waitUntil { $0.started == ["A"] })

        viewTask.cancel()
        await viewTask.value

        #expect(await recorder.waitUntil { $0.cancelled == ["A"] })
        await effect.finish()
        #expect(store.state.log.isEmpty)
        #expect(store.runningTaskCount == 0)
    }

    @Test("send로 바뀐 state를 관찰자에게 알린다")
    func notifiesObservers() {
        let store = makeStore()
        let changed = OSAllocatedUnfairLock(initialState: false)

        withObservationTracking {
            _ = store.state
        } onChange: {
            changed.withLock { $0 = true }
        }
        store.send(.increment)

        #expect(changed.withLock { $0 })
    }
}
