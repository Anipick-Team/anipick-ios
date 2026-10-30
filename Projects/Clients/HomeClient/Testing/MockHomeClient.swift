import ClientCore
import HomeClientInterface
import os

/// 요청을 기록하고 정해 둔 결과를 차례로 돌려준다 (다 쓰면 마지막 것을 반복)
public final class MockHomeClient: HomeClient {
    public enum Request: Hashable, Sendable {
        case recommendations(lastId: Int?, lastValue: String?)
        case recentRecommendations(animeId: Int, lastId: Int?, lastValue: String?)
        case comingSoon(sort: String, lastId: Int?, includeAdult: Bool)
        case weekday(day: String, sort: String, lastId: Int?, size: Int)
        case trending
        case homeRecommendations
        case homeRecentRecommendations(animeId: Int)
        case homeRecentReviews
        case upcomingSeason
        case homeComingSoon
        case popular
        case searchAnimes(query: String, lastId: Int?)
        case searchPersons(query: String, lastId: Int?)
        case searchStudios(query: String, lastId: Int?)
        case trackingLog(String)
    }

    private struct State {
        var recommendations: [Result<RecommendationPage?, TransportError>] = []
        var comingSoon: [Result<ComingSoonPage?, TransportError>] = []
        var weekday: [Result<WeekdayAnimePage, TransportError>] = []
        var popular: Result<[HomeAnime], TransportError> = .success([])
        var animePages: [Result<SearchPage<SearchAnime>?, TransportError>] = []
        var personPages: [Result<SearchPage<SearchPerson>?, TransportError>] = []
        var studioPages: [Result<SearchPage<SearchStudio>?, TransportError>] = []
        var keywords: [String] = []
        var home = HomeStub()
        var requests: [Request] = []
    }

    /// 홈 메인 화면의 결과
    public struct HomeStub: Sendable {
        public var trending: Result<[TrendingAnime], TransportError>
        public var recommendations: Result<RecommendationPage?, TransportError>
        public var recentRecommendations: Result<RecommendationPage?, TransportError>
        public var recentReviews: Result<[HomeReview], TransportError>
        public var upcoming: Result<UpcomingSeason, TransportError>
        public var comingSoon: Result<[HomeAnime], TransportError>

        public init(
            trending: Result<[TrendingAnime], TransportError> = .success([]),
            recommendations: Result<RecommendationPage?, TransportError> = .success(nil),
            recentRecommendations: Result<RecommendationPage?, TransportError> = .success(nil),
            recentReviews: Result<[HomeReview], TransportError> = .success([]),
            upcoming: Result<UpcomingSeason, TransportError> = .failure(.decoding),
            comingSoon: Result<[HomeAnime], TransportError> = .success([])
        ) {
            self.trending = trending
            self.recommendations = recommendations
            self.recentRecommendations = recentRecommendations
            self.recentReviews = recentReviews
            self.upcoming = upcoming
            self.comingSoon = comingSoon
        }
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

    public func weekdayNewAnimes(day: String, sort: String, lastId: Int?, size: Int)
        async throws(TransportError)
        -> WeekdayAnimePage
    {
        let result = state.withLock { state -> Result<WeekdayAnimePage, TransportError> in
            state.requests.append(.weekday(day: day, sort: sort, lastId: lastId, size: size))
            return Self.next(&state.weekday) ?? .success(WeekdayAnimePage(animes: [], lastId: nil))
        }
        await pause()
        return try result.get()
    }

    public func stubHome(_ home: HomeStub) {
        state.withLock { $0.home = home }
    }

    private func respond<Value: Sendable>(
        _ request: Request, _ pick: @Sendable (HomeStub) -> Result<Value, TransportError>
    )
        async throws(TransportError) -> Value
    {
        let result = state.withLock { state in
            state.requests.append(request)
            return pick(state.home)
        }
        await pause()
        return try result.get()
    }

    public func trending() async throws(TransportError) -> [TrendingAnime] {
        return try await respond(.trending) { $0.trending }
    }

    public func homeRecommendations() async throws(TransportError) -> RecommendationPage? {
        return try await respond(.homeRecommendations) { $0.recommendations }
    }

    public func homeRecentRecommendations(animeId: Int) async throws(TransportError)
        -> RecommendationPage?
    {
        return try await respond(.homeRecentRecommendations(animeId: animeId)) {
            $0.recentRecommendations
        }
    }

    public func homeRecentReviews() async throws(TransportError) -> [HomeReview] {
        return try await respond(.homeRecentReviews) { $0.recentReviews }
    }

    public func upcomingSeason() async throws(TransportError) -> UpcomingSeason {
        return try await respond(.upcomingSeason) { $0.upcoming }
    }

    public func homeComingSoon() async throws(TransportError) -> [HomeAnime] {
        return try await respond(.homeComingSoon) { $0.comingSoon }
    }

    /// 검색 결과. 각 목록은 차례로 (다 쓰면 마지막 것을 반복, 없으면 nil)
    public func stubSearch(
        popular: Result<[HomeAnime], TransportError> = .success([]),
        animes: [Result<SearchPage<SearchAnime>?, TransportError>] = [],
        persons: [Result<SearchPage<SearchPerson>?, TransportError>] = [],
        studios: [Result<SearchPage<SearchStudio>?, TransportError>] = [],
        keywords: [String] = []
    ) {
        state.withLock {
            $0.popular = popular
            $0.animePages = animes
            $0.personPages = persons
            $0.studioPages = studios
            $0.keywords = keywords
        }
    }

    public var storedKeywords: [String] {
        return state.withLock { $0.keywords }
    }

    public func popularAnimes() async throws(TransportError) -> [HomeAnime] {
        let result = state.withLock { state in
            state.requests.append(.popular)
            return state.popular
        }
        await pause()
        return try result.get()
    }

    public func searchAnimes(query: String, lastId: Int?) async throws(TransportError)
        -> SearchPage<SearchAnime>?
    {
        let result = state.withLock { state in
            state.requests.append(.searchAnimes(query: query, lastId: lastId))
            return Self.next(&state.animePages) ?? .success(nil)
        }
        await pause()
        return try result.get()
    }

    public func searchPersons(query: String, lastId: Int?) async throws(TransportError)
        -> SearchPage<SearchPerson>?
    {
        let result = state.withLock { state in
            state.requests.append(.searchPersons(query: query, lastId: lastId))
            return Self.next(&state.personPages) ?? .success(nil)
        }
        await pause()
        return try result.get()
    }

    public func searchStudios(query: String, lastId: Int?) async throws(TransportError)
        -> SearchPage<SearchStudio>?
    {
        let result = state.withLock { state in
            state.requests.append(.searchStudios(query: query, lastId: lastId))
            return Self.next(&state.studioPages) ?? .success(nil)
        }
        await pause()
        return try result.get()
    }

    public func sendTrackingLog(_ url: String) async {
        state.withLock { $0.requests.append(.trackingLog(url)) }
    }

    public func recentKeywords() -> [String] {
        return state.withLock { $0.keywords }
    }

    public func saveRecentKeyword(_ keyword: String) {
        state.withLock {
            $0.keywords.removeAll { $0 == keyword }
            $0.keywords.insert(keyword, at: 0)
        }
    }

    public func setRecentKeywords(_ keywords: [String]) {
        state.withLock { $0.keywords = keywords }
    }

    public func clearRecentKeywords() {
        state.withLock { $0.keywords = [] }
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

extension SearchAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int, clickLog: String? = nil, impressionLog: String? = nil)
        -> SearchAnime
    {
        return SearchAnime(
            animeId: id, title: "애니 \(id)", coverImageUrl: nil, clickLog: clickLog,
            impressionLog: impressionLog)
    }
}

extension SearchPerson {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> SearchPerson {
        return SearchPerson(personId: id, name: "인물 \(id)", profileImage: nil)
    }
}

extension SearchStudio {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> SearchStudio {
        return SearchStudio(studioId: id, name: "제작사 \(id)")
    }
}
