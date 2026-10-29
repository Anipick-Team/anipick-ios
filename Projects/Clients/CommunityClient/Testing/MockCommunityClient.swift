import ClientCore
import CommunityClientInterface
import os

/// 요청을 기록하고 정해 둔 결과를 차례로 돌려준다 (다 쓰면 마지막 것을 반복)
public final class MockCommunityClient: CommunityClient {
    public struct BoardsRequest: Equatable, Sendable {
        public let sort: String
        public let keyword: String?
        public let lastValue: String?
        public let lastId: Int?

        public init(sort: String, keyword: String?, lastValue: String?, lastId: Int?) {
            self.sort = sort
            self.keyword = keyword
            self.lastValue = lastValue
            self.lastId = lastId
        }
    }

    private struct State {
        var boards: [Result<CommunityBoardPage, TransportError>]
        var requests: [BoardsRequest] = []
    }

    private let state: OSAllocatedUnfairLock<State>
    private let delay: Duration

    public init(boards: [Result<CommunityBoardPage, TransportError>] = [], delay: Duration = .zero)
    {
        state = OSAllocatedUnfairLock(initialState: State(boards: boards))
        self.delay = delay
    }

    public var boardRequests: [BoardsRequest] {
        return state.withLock { $0.requests }
    }

    public func exploreBoards(
        sort: String,
        keyword: String?,
        lastValue: String?,
        lastId: Int?
    ) async throws(TransportError) -> CommunityBoardPage {
        let result = state.withLock { state -> Result<CommunityBoardPage, TransportError>? in
            state.requests.append(
                BoardsRequest(sort: sort, keyword: keyword, lastValue: lastValue, lastId: lastId))
            return state.boards.count > 1 ? state.boards.removeFirst() : state.boards.first
        }
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
        return try (result ?? .success(CommunityBoardPage(boards: [], lastId: nil, lastValue: nil)))
            .get()
    }
}

extension CommunityBoard {
    /// 테스트·Example용
    public static func sample(_ id: Int, genres: [String] = ["액션", "판타지"]) -> CommunityBoard {
        return CommunityBoard(seriesId: id, title: "애니 \(id)", coverImageUrl: nil, genres: genres)
    }
}
