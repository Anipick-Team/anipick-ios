import ClientCore
import MyInfoClientInterface
import os

/// 요청을 기록하고 정해 둔 페이지를 돌려준다 (Store 테스트·Example 앱).
public final class MockMyInfoClient: MyInfoClient {
    public enum Request: Equatable, Sendable {
        case watchList(WatchStatus, lastId: Int?)
        case likedAnimes(lastId: Int?)
        case likedPersons(lastId: Int?)
    }

    public struct Scenario: Sendable {
        public var animePage: Result<MyPage<MyAnime>, TransportError>
        public var personPage: Result<MyPage<MyPerson>, TransportError>

        public init(
            animePage: Result<MyPage<MyAnime>, TransportError> = .success(
                MyPage(count: 0, items: [], lastId: nil)),
            personPage: Result<MyPage<MyPerson>, TransportError> = .success(
                MyPage(count: 0, items: [], lastId: nil))
        ) {
            self.animePage = animePage
            self.personPage = personPage
        }
    }

    private let state: OSAllocatedUnfairLock<(scenario: Scenario, requests: [Request])>

    public init(_ scenario: Scenario = Scenario()) {
        state = OSAllocatedUnfairLock(initialState: (scenario, []))
    }

    public var requests: [Request] {
        return state.withLock { $0.requests }
    }

    public func watchList(
        _ status: WatchStatus,
        lastId: Int?
    ) async throws(TransportError) -> MyPage<MyAnime> {
        return try state.withLock {
            $0.requests.append(.watchList(status, lastId: lastId))
            return $0.scenario.animePage
        }
        .get()
    }

    public func likedAnimes(lastId: Int?) async throws(TransportError) -> MyPage<MyAnime> {
        return try state.withLock {
            $0.requests.append(.likedAnimes(lastId: lastId))
            return $0.scenario.animePage
        }
        .get()
    }

    public func likedPersons(lastId: Int?) async throws(TransportError) -> MyPage<MyPerson> {
        return try state.withLock {
            $0.requests.append(.likedPersons(lastId: lastId))
            return $0.scenario.personPage
        }
        .get()
    }
}

extension MyAnime {
    /// 테스트·Example용
    public static func sample(_ id: Int, rating: Double? = nil) -> MyAnime {
        return MyAnime(animeId: id, title: "애니 \(id)", coverImageUrl: nil, myRating: rating)
    }
}

extension MyPerson {
    /// 테스트·Example용
    public static func sample(_ id: Int) -> MyPerson {
        return MyPerson(personId: id, name: "인물 \(id)", profileImageUrl: nil)
    }
}
