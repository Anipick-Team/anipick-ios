import ClientCore
import DetailClientInterface
import os

/// 요청을 기록하고 정해 둔 결과를 차례로 돌려준다 (다 쓰면 마지막 것을 반복, 없으면 nil)
public final class MockDetailClient: DetailClient {
    public enum Request: Hashable, Sendable {
        case series(animeId: Int, lastId: Int?)
        case recommendations(animeId: Int, lastId: Int?)
        case studio(id: Int, lastId: Int?, lastValue: String?)
        case characters(animeId: Int)
        case person(id: Int, lastId: Int?)
        case personLike(id: Int, liked: Bool)
        case animeInfo(Int)
        case detailCast(Int)
        case detailSeries(Int)
        case detailRecommendations(Int)
        case animeLike(id: Int, liked: Bool)
        case watchStatus(animeId: Int, status: String)
        case deleteWatchStatus(Int)
    }

    /// 애니 상세 화면의 결과
    public struct AnimeStub: Sendable {
        public var info: Result<AnimeInfo, TransportError>
        public var cast: Result<[CastMember], TransportError>
        public var series: Result<[DetailAnime], TransportError>
        public var recommendations: Result<[DetailAnime], TransportError>
        public var like: Result<Void, TransportError>
        /// 차례로 돌려줄 시청 상태 code (다 쓰면 200)
        public var statusCodes: [Int]

        public init(
            info: Result<AnimeInfo, TransportError> = .failure(.decoding),
            cast: Result<[CastMember], TransportError> = .success([]),
            series: Result<[DetailAnime], TransportError> = .success([]),
            recommendations: Result<[DetailAnime], TransportError> = .success([]),
            like: Result<Void, TransportError> = .success(()), statusCodes: [Int] = []
        ) {
            self.info = info
            self.cast = cast
            self.series = series
            self.recommendations = recommendations
            self.like = like
            self.statusCodes = statusCodes
        }
    }

    private struct State {
        var series: [Result<SeriesPage?, TransportError>] = []
        var recommendations: [Result<AnimeRecommendationPage?, TransportError>] = []
        var studio: [Result<StudioPage, TransportError>] = []
        var characters: Result<[CastMember], TransportError> = .success([])
        var person: [Result<PersonPage, TransportError>] = []
        var anime = AnimeStub()
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

    public func stubStudio(_ pages: [Result<StudioPage, TransportError>]) {
        state.withLock { $0.studio = pages }
    }

    public func stubCharacters(_ result: Result<[CastMember], TransportError>) {
        state.withLock { $0.characters = result }
    }

    public func studio(id: Int, lastId: Int?, lastValue: String?) async throws(TransportError)
        -> StudioPage
    {
        let result = state.withLock { state in
            state.requests.append(.studio(id: id, lastId: lastId, lastValue: lastValue))
            return Self.next(&state.studio) ?? .failure(.decoding)
        }
        await pause()
        return try result.get()
    }

    public func characters(animeId: Int) async throws(TransportError) -> [CastMember] {
        let result = state.withLock { state in
            state.requests.append(.characters(animeId: animeId))
            return state.characters
        }
        await pause()
        return try result.get()
    }

    public func stubPerson(_ pages: [Result<PersonPage, TransportError>]) {
        state.withLock { $0.person = pages }
    }

    public func person(id: Int, lastId: Int?) async throws(TransportError) -> PersonPage {
        let result = state.withLock { state in
            state.requests.append(.person(id: id, lastId: lastId))
            return Self.next(&state.person) ?? .failure(.decoding)
        }
        await pause()
        return try result.get()
    }

    public func setPersonLike(id: Int, liked: Bool) async throws(TransportError) {
        state.withLock { $0.requests.append(.personLike(id: id, liked: liked)) }
        await pause()
    }

    public func stubAnime(_ anime: AnimeStub) {
        state.withLock { $0.anime = anime }
    }

    private func respond<Value: Sendable>(
        _ request: Request, _ pick: @Sendable (inout AnimeStub) -> Result<Value, TransportError>
    ) async throws(TransportError) -> Value {
        let result = state.withLock { state in
            state.requests.append(request)
            return pick(&state.anime)
        }
        await pause()
        return try result.get()
    }

    public func animeInfo(id: Int) async throws(TransportError) -> AnimeInfo {
        return try await respond(.animeInfo(id)) { $0.info }
    }

    public func detailCast(animeId: Int) async throws(TransportError) -> [CastMember] {
        return try await respond(.detailCast(animeId)) { $0.cast }
    }

    public func detailSeries(animeId: Int) async throws(TransportError) -> [DetailAnime] {
        return try await respond(.detailSeries(animeId)) { $0.series }
    }

    public func detailRecommendations(animeId: Int) async throws(TransportError) -> [DetailAnime] {
        return try await respond(.detailRecommendations(animeId)) { $0.recommendations }
    }

    public func setAnimeLike(id: Int, liked: Bool) async throws(TransportError) {
        try await respond(.animeLike(id: id, liked: liked)) { $0.like }
    }

    public func setWatchStatus(animeId: Int, status: String) async throws(TransportError) -> Int {
        return try await respond(.watchStatus(animeId: animeId, status: status)) { stub in
            guard !stub.statusCodes.isEmpty else {
                return .success(200)
            }
            return .success(stub.statusCodes.removeFirst())
        }
    }

    public func deleteWatchStatus(animeId: Int) async throws(TransportError) {
        try await respond(.deleteWatchStatus(animeId)) { _ in .success(()) }
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

extension StudioAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int, year: String) -> StudioAnime {
        return StudioAnime(animeId: id, title: "애니 \(id)", coverImageUrl: nil, seasonYear: year)
    }
}

extension CastMember {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> CastMember {
        return CastMember(
            character: CastPerson(id: id, name: "캐릭터 \(id)", imageUrl: nil),
            voiceActor: CastPerson(id: 100 + id, name: "성우 \(id)", imageUrl: nil))
    }
}

extension PersonWork {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> PersonWork {
        return PersonWork(
            animeId: 10 + id, animeTitle: "애니 \(id)", characterId: id, characterName: "배역 \(id)",
            characterImageUrl: nil)
    }
}

extension AnimeInfo {
    /// 테스트·Example용
    public static func sample(
        _ id: Int, title: String? = "원피스", isLiked: Bool = false, watchStatus: String? = nil
    )
        -> AnimeInfo
    {
        return AnimeInfo(
            animeId: id, title: title, coverImageUrl: nil, bannerImageUrl: nil, description: "설명",
            averageRating: "4.5", isLiked: isLiked, watchStatus: watchStatus, type: "TVA",
            reviewCount: 12,
            genres: ["액션", "모험"], episode: 24, airDate: "2025년 3분기", status: "방영 중", age: "15세",
            studios: [AnimeInfo.Studio(studioId: 3, name: "MAPPA")])
    }
}
