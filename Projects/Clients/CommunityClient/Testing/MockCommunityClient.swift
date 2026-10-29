import ClientCore
import CommunityClientInterface
import Foundation
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

    /// 글 저장 요청 기록
    public enum SaveRequest: Equatable, Sendable {
        case upload(fileName: String, bytes: Int)
        case create(seriesId: Int, PostDraft)
        case update(id: Int, PostDraft)
    }

    private struct State {
        var boards: [Result<CommunityBoardPage, TransportError>]
        var requests: [BoardsRequest] = []
        var uploads: [Result<Int?, TransportError>] = [.success(1)]
        var saveResult: Result<PostSaveOutcome, TransportError> = .success(.saved)
        var saveRequests: [SaveRequest] = []
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

    public var saveRequests: [SaveRequest] {
        return state.withLock { $0.saveRequests }
    }

    /// 업로드 결과를 차례로 (다 쓰면 마지막 것을 반복). 저장 결과
    public func stubSave(
        uploads: [Result<Int?, TransportError>] = [.success(1)],
        result: Result<PostSaveOutcome, TransportError> = .success(.saved)
    ) {
        state.withLock {
            $0.uploads = uploads
            $0.saveResult = result
        }
    }

    public func imageURL(id: Int) -> URL {
        return URL(string: "https://image.test/api/image/\(id)")!
    }

    public func uploadPostImage(jpeg: Data, fileName: String) async throws(TransportError) -> Int? {
        let result = state.withLock { state in
            state.saveRequests.append(.upload(fileName: fileName, bytes: jpeg.count))
            return state.uploads.count > 1 ? state.uploads.removeFirst() : state.uploads[0]
        }
        await pause()
        return try result.get()
    }

    public func createPost(seriesId: Int, _ draft: PostDraft) async throws(TransportError)
        -> PostSaveOutcome
    {
        return try await save(.create(seriesId: seriesId, draft))
    }

    public func updatePost(id: Int, _ draft: PostDraft) async throws(TransportError)
        -> PostSaveOutcome
    {
        return try await save(.update(id: id, draft))
    }

    private func save(_ request: SaveRequest) async throws(TransportError) -> PostSaveOutcome {
        let result = state.withLock { state in
            state.saveRequests.append(request)
            return state.saveResult
        }
        await pause()
        return try result.get()
    }

    private func pause() async {
        if delay > .zero {
            try? await Task.sleep(for: delay)
        }
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
