import ClientCore
import DetailClientInterface
import os

/// 요청을 기록하고 정해 둔 결과를 차례로 돌려준다 (다 쓰면 마지막 것을 반복, 없으면 nil)
public final class MockDetailClient: DetailClient {
    public enum Request: Hashable, Sendable {
        case series(animeId: Int, lastId: Int?)
        case recommendations(animeId: Int, lastId: Int?)
    }

    private struct State {
        var series: [Result<SeriesPage?, TransportError>] = []
        var recommendations: [Result<AnimeRecommendationPage?, TransportError>] = []
        var requests: [Request] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let delay: Duration

    public init(delay: Duration = .zero) {
        self.delay = delay
    }

    public var requests: [Request] {
        return state.withLock { $0.requests }
    }

    public func stubSeries(_ pages: [Result<SeriesPage?, TransportError>]) {
        state.withLock { $0.series = pages }
    }

    public func stubRecommendations(_ pages: [Result<AnimeRecommendationPage?, TransportError>]) {
        state.withLock { $0.recommendations = pages }
    }

    public func series(animeId: Int, lastId: Int?) async throws(TransportError) -> SeriesPage? {
        let result = state.withLock { state in
            state.requests.append(.series(animeId: animeId, lastId: lastId))
            return Self.next(&state.series) ?? .success(nil)
        }
        await pause()
        return try result.get()
    }

    public func recommendations(animeId: Int, lastId: Int?) async throws(TransportError)
        -> AnimeRecommendationPage?
    {
        let result = state.withLock { state in
            state.requests.append(.recommendations(animeId: animeId, lastId: lastId))
            return Self.next(&state.recommendations) ?? .success(nil)
        }
        await pause()
        return try result.get()
    }

    private static func next<Value>(_ queue: inout [Value]) -> Value? {
        guard let first = queue.first else {
            return nil
        }
        if queue.count > 1 {
            queue.removeFirst()
        }
        return first
    }

    private func pause() async {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
    }
}

extension DetailAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> DetailAnime {
        return DetailAnime(animeId: id, title: "애니 \(id)", coverImageUrl: nil)
    }
}
