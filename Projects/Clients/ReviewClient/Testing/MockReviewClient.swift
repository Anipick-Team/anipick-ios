import ClientCore
import ReviewClientInterface
import os

/// 시나리오형 가짜. 결과·지연을 정해 두고 받은 요청을 기록한다 (Store 테스트·Example 앱).
public final class MockReviewClient: ReviewClient {
    public struct WrittenReview: Equatable, Sendable {
        public let animeId: Int
        public let content: String
        public let rating: Double
        public let isSpoiler: Bool

        public init(animeId: Int, content: String, rating: Double, isSpoiler: Bool) {
            self.animeId = animeId
            self.content = content
            self.rating = rating
            self.isSpoiler = isSpoiler
        }
    }

    private struct State {
        var result: Result<Void, TransportError>
        var delay: Duration
        var written: [WrittenReview] = []
        var deletedIds: [Int] = []
    }

    private let state: OSAllocatedUnfairLock<State>

    public init(result: Result<Void, TransportError> = .success(()), delay: Duration = .zero) {
        state = OSAllocatedUnfairLock(initialState: State(result: result, delay: delay))
    }

    public var written: [WrittenReview] {
        return state.withLock { $0.written }
    }

    public var deletedIds: [Int] {
        return state.withLock { $0.deletedIds }
    }

    public func deleteReview(id: Int) async throws(TransportError) {
        try state.withLock {
            $0.deletedIds.append(id)
            return $0.result
        }
        .get()
    }

    public func writeReview(
        animeId: Int,
        content: String,
        rating: Double,
        isSpoiler: Bool
    ) async throws(TransportError) {
        let delay = state.withLock {
            $0.written.append(
                WrittenReview(
                    animeId: animeId,
                    content: content,
                    rating: rating,
                    isSpoiler: isSpoiler
                )
            )
            return $0.delay
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        try state.withLock { $0.result }.get()
    }
}
