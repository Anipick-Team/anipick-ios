//
//  AppEntryViewModelTests.swift
//  AniPickTests
//
//  앱 시작 요청 (Phase 5에서 레거시 Alamofire → HTTPClient)
//

import Foundation
import ClientCore
import MetadataClientInterface
import Networking
import Testing
import os

@testable import AniPick

/// 앞의 `failures`번은 실패하고 그 뒤로 성공한다
private nonisolated final class FlakyMetadataClient: MetadataClient {
    private let state: OSAllocatedUnfairLock<(failures: Int, calls: Int)>

    init(failures: Int) {
        state = OSAllocatedUnfairLock(initialState: (failures, 0))
    }

    var calls: Int {
        return state.withLock { $0.calls }
    }

    func cachedGenres() -> [Genre] { return [] }
    func cachedSeasonYears() -> [Int] { return [] }
    func cachedTypes() -> [String] { return [] }

    func refresh() async -> Bool {
        return state.withLock { state in
            state.calls += 1
            return state.calls > state.failures
        }
    }
}

/// 버전 확인은 인증 요청이다 (레거시 Authorization 헤더)
private nonisolated struct FixedToken: TokenProviding {
    func accessToken() async -> String? { return "token" }
    func refreshAccessToken() async throws(TransportError) {}
}

@MainActor
@Suite("AppEntryViewModel", .timeLimit(.minutes(1)))
struct AppEntryViewModelTests {
    private let server = StubServer()

    private func makeViewModel(metadata: any MetadataClient) -> AppEntryViewModel {
        let client = HTTPClient(baseURL: server.url(""), configuration: server.configuration, tokenProvider: FixedToken())
        return AppEntryViewModel(client: client, metadataClient: metadata, retryDelay: .zero)
    }

    @Test("AE1. 메타데이터는 성공하면 더 받지 않는다")
    func metaDataStopsOnSuccess() async {
        let metadata = FlakyMetadataClient(failures: 1)

        await makeViewModel(metadata: metadata).fetchMetaData()

        #expect(metadata.calls == 2)
    }

    @Test("AE2. 메타데이터는 실패하면 3번까지 다시 받는다 (모두 4번)")
    func metaDataRetriesThreeTimes() async {
        let metadata = FlakyMetadataClient(failures: 100)

        await makeViewModel(metadata: metadata).fetchMetaData()

        #expect(metadata.calls == 4)
    }

    @Test("AE3. 버전 확인: GET api/version?userAppVersion=…&platform=IOS")
    func checksVersion() async throws {
        server.respondAlways(.json(status: 200, body: #"{"code":200,"value":"SUCCESS"}"#))

        await makeViewModel(metadata: FlakyMetadataClient(failures: 0)).checkVersion()

        let request = try #require(server.requests.first)
        let components = try #require(request.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })
        #expect(request.httpMethod == "GET")
        #expect(components.path == "/api/version")
        #expect(components.queryItems?.first(where: { $0.name == "platform" })?.value == "IOS")
        #expect(components.queryItems?.contains(where: { $0.name == "userAppVersion" }) == true)
    }
}
