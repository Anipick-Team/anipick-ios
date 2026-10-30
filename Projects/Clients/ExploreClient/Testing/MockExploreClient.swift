import ClientCore
import ExploreClientInterface
import os

/// 요청을 기록하고 정해 둔 페이지를 돌려준다.
public final class MockExploreClient: ExploreClient {
    public struct Request: Equatable, Sendable {
        public let query: String?
        public let year: Int?
        public let season: Int?
        public let genreId: Int?
        public let lastId: Int?

        public init(query: String?, year: Int?, season: Int?, genreId: Int?, lastId: Int?) {
            self.query = query
            self.year = year
            self.season = season
            self.genreId = genreId
            self.lastId = lastId
        }
    }

    private let state:
        OSAllocatedUnfairLock<(page: Result<OnboardingPage?, TransportError>, requests: [Request])>
    private let exploreState:
        OSAllocatedUnfairLock<
            (pages: [Result<ExplorePage?, TransportError>], queries: [ExploreQuery])
        >

    public init(
        _ page: Result<OnboardingPage?, TransportError> = .success(nil),
        explorePages: [Result<ExplorePage?, TransportError>] = []
    ) {
        state = OSAllocatedUnfairLock(initialState: (page, []))
        exploreState = OSAllocatedUnfairLock(initialState: (explorePages, []))
    }

    public var exploreQueries: [ExploreQuery] {
        return exploreState.withLock { $0.queries }
    }

    /// 정해 둔 결과를 차례로 돌려준다 (다 쓰면 마지막 것을 반복, 없으면 nil)
    public func exploreAnimes(_ query: ExploreQuery) async throws(TransportError) -> ExplorePage? {
        let result = exploreState.withLock { state -> Result<ExplorePage?, TransportError> in
            state.queries.append(query)
            guard let first = state.pages.first else {
                return .success(nil)
            }
            if state.pages.count > 1 {
                state.pages.removeFirst()
            }
            return first
        }
        return try result.get()
    }

    public var requests: [Request] {
        return state.withLock { $0.requests }
    }

    public func onboardingAnimes(
        query: String?,
        year: Int?,
        season: Int?,
        genreId: Int?,
        lastId: Int?
    ) async throws(TransportError) -> OnboardingPage? {
        return try state.withLock {
            $0.requests.append(
                Request(query: query, year: year, season: season, genreId: genreId, lastId: lastId))
            return $0.page
        }
        .get()
    }
}

extension OnboardingAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> OnboardingAnime {
        return OnboardingAnime(
            animeId: id, title: "애니 \(id)", coverImageUrl: nil, genres: ["액션", "SF"])
    }
}

extension ExploreAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> ExploreAnime {
        return ExploreAnime(animeId: id, title: "애니 \(id)", coverImageUrl: nil)
    }
}
