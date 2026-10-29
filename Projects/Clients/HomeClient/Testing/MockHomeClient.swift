import ClientCore
import HomeClientInterface
import os

/// 요청을 기록하고 정해 둔 결과를 차례로 돌려준다 (다 쓰면 마지막 것을 반복)
public final class MockHomeClient: HomeClient {
    public enum Request: Hashable, Sendable {
        case recommendations(lastId: Int?, lastValue: String?)
        case recentRecommendations(animeId: Int, lastId: Int?, lastValue: String?)
        case comingSoon(sort: String, lastId: Int?, includeAdult: Bool)
        case weekday(day: String, sort: String, lastId: Int?)
    }

    private struct State {
        var recommendations: [Result<RecommendationPage?, TransportError>] = []
        var comingSoon: [Result<ComingSoonPage?, TransportError>] = []
        var weekday: [Result<WeekdayAnimePage, TransportError>] = []
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

    /// 두 추천 요청이 함께 쓰는 결과
    public func stubRecommendations(_ pages: [Result<RecommendationPage?, TransportError>]) {
        state.withLock { $0.recommendations = pages }
    }

    public func stubComingSoon(_ pages: [Result<ComingSoonPage?, TransportError>]) {
        state.withLock { $0.comingSoon = pages }
    }

    public func stubWeekday(_ pages: [Result<WeekdayAnimePage, TransportError>]) {
        state.withLock { $0.weekday = pages }
    }

    public func comingSoon(sort: String, lastId: Int?, includeAdult: Bool)
        async throws(TransportError)
        -> ComingSoonPage?
    {
        let result = state.withLock { state -> Result<ComingSoonPage?, TransportError> in
            state.requests.append(
                .comingSoon(sort: sort, lastId: lastId, includeAdult: includeAdult))
            return Self.next(&state.comingSoon) ?? .success(nil)
        }
        await pause()
        return try result.get()
    }

    public func weekdayNewAnimes(day: String, sort: String, lastId: Int?)
        async throws(TransportError)
        -> WeekdayAnimePage
    {
        let result = state.withLock { state -> Result<WeekdayAnimePage, TransportError> in
            state.requests.append(.weekday(day: day, sort: sort, lastId: lastId))
            return Self.next(&state.weekday) ?? .success(WeekdayAnimePage(animes: [], lastId: nil))
        }
        await pause()
        return try result.get()
    }

    /// 앞에서부터 꺼내고, 마지막 하나는 계속 돌려준다
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

    public func recommendations(lastId: Int?, lastValue: String?) async throws(TransportError)
        -> RecommendationPage?
    {
        return try await recommend(.recommendations(lastId: lastId, lastValue: lastValue))
    }

    public func recentRecommendations(animeId: Int, lastId: Int?, lastValue: String?)
        async throws(TransportError) -> RecommendationPage?
    {
        return try await recommend(
            .recentRecommendations(animeId: animeId, lastId: lastId, lastValue: lastValue))
    }

    private func recommend(_ request: Request) async throws(TransportError) -> RecommendationPage? {
        let result = state.withLock { state -> Result<RecommendationPage?, TransportError> in
            state.requests.append(request)
            guard let first = state.recommendations.first else {
                return .success(nil)
            }
            if state.recommendations.count > 1 {
                state.recommendations.removeFirst()
            }
            return first
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try result.get()
    }
}

extension HomeAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> HomeAnime {
        return HomeAnime(animeId: id, title: "애니 \(id)", coverImageUrl: nil)
    }
}

extension ComingSoonAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int, releaseDate: String? = "2026.11.01") -> ComingSoonAnime {
        return ComingSoonAnime(
            animeId: id, title: "애니 \(id)", coverImageUrl: nil, releaseDate: releaseDate)
    }
}
