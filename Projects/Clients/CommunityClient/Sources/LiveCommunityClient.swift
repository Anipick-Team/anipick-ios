import ClientCore
import CommunityClientInterface
import Foundation
import Networking

public struct LiveCommunityClient: CommunityClient {
    private let client: HTTPClient

    /// - Parameter client: 인증 클라이언트
    public init(client: HTTPClient) {
        self.client = client
    }

    public func exploreBoards(
        sort: String,
        keyword: String?,
        lastValue: String?,
        lastId: Int?
    ) async throws(TransportError) -> CommunityBoardPage {
        let response = try await client.send(
            Self.exploreBoardsEndpoint(
                sort: sort, keyword: keyword, lastValue: lastValue, lastId: lastId))
        let result = response.result
        return CommunityBoardPage(
            boards: (result?.boards ?? []).map {
                CommunityBoard(
                    seriesId: $0.seriesId, title: $0.title, coverImageUrl: $0.coverImageUrl,
                    genres: ($0.genres ?? []).compactMap(\.name))
            },
            lastId: result?.cursor?.lastId,
            lastValue: result?.cursor?.lastValue
        )
    }

    static func exploreBoardsEndpoint(
        sort: String,
        keyword: String?,
        lastValue: String?,
        lastId: Int?
    ) -> Endpoint<BoardsResult> {
        let parameters: [String: String?] = [
            "sort": sort, "keyword": keyword, "lastValue": lastValue,
            "lastId": lastId.map(String.init),
            "size": "20",
        ]
        return Endpoint(
            method: .get,
            path: "api/community/explore/boards",
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }
}

/// 레거시 `CommunityBoardPage`
struct BoardsResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
        let lastValue: String?
    }

    struct Genre: Decodable, Sendable {
        let name: String?
    }

    struct Board: Decodable, Sendable {
        let seriesId: Int
        let title: String?
        let coverImageUrl: String?
        let genres: [Genre]?
    }

    let cursor: Cursor?
    let boards: [Board]?
}
