import Foundation
import Testing

import ClientCore
import Networking

private struct Profile: Codable, Equatable, Sendable {
    let nickname: String
}

private struct LoginRequest: Encodable, Sendable {
    let email: String
}

@Suite("HTTPClient 요청 만들기")
struct HTTPClientRequestTests {
    let server = StubServer()

    @Test("GET은 기본 주소 + 경로 + 쿼리로 보내고 본문을 싣지 않는다")
    func buildsGetRequest() async throws {
        server.reply(.json(status: 200, body: #"{"code":200,"value":"OK"}"#))
        let client = HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: nil)

        _ = try await client.send(
            Endpoint<EmptyResult>(
                method: .get,
                path: "api/animes/ranking",
                query: [URLQueryItem(name: "page", value: "2")],
                requiresAuth: false
            )
        )

        let request = try #require(server.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://\(server.host)/api/animes/ranking?page=2")
        #expect(server.bodies.first == Data())
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("JSON 본문은 application/json으로 보낸다")
    func buildsJSONRequest() async throws {
        server.reply(.json(status: 200, body: #"{"code":200,"value":"OK"}"#))
        let client = HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: nil)

        _ = try await client.send(
            Endpoint<EmptyResult>(
                method: .post,
                path: "api/users/login",
                body: .json(LoginRequest(email: "a@b.com")),
                requiresAuth: false
            )
        )

        let request = try #require(server.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(server.bodies.first == Data(#"{"email":"a@b.com"}"#.utf8))
    }

    @Test("인증이 필요한 요청에는 Bearer 토큰을 붙인다")
    func addsBearerToken() async throws {
        server.reply(.json(status: 200, body: #"{"code":200,"value":"OK"}"#))
        let client = HTTPClient(
            baseURL: server.baseURL,
            configuration: server.configuration,
            tokenProvider: FakeTokenProvider(token: "access-1")
        )

        _ = try await client.send(
            Endpoint<EmptyResult>(method: .get, path: "api/me", requiresAuth: true))

        let request = try #require(server.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-1")
    }

    @Test("요청 헤더는 기본 헤더보다 우선한다 (토큰 갱신 요청의 refresh 토큰)")
    func endpointHeadersOverrideDefaults() async throws {
        server.reply(.json(status: 200, body: #"{"code":200,"value":"OK"}"#))
        let client = HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: nil)

        _ = try await client.send(
            Endpoint<EmptyResult>(
                method: .post,
                path: "api/tokens/refresh",
                headers: ["Authorization": "Bearer refresh-1"],
                requiresAuth: false
            )
        )

        let request = try #require(server.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer refresh-1")
    }
}

@Suite("HTTPClient 응답")
struct HTTPClientResponseTests {
    let server = StubServer()

    private var client: HTTPClient {
        return HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: nil)
    }

    @Test("서버 응답의 code·value·result를 디코딩한다")
    func decodesEnvelope() async throws {
        server.reply(
            .json(status: 200, body: #"{"code":200,"value":"OK","result":{"nickname":"애니픽"}}"#)
        )

        let response = try await client.send(
            Endpoint<Profile>(method: .get, path: "api/me", requiresAuth: false)
        )

        #expect(response.code == 200)
        #expect(response.value == "OK")
        #expect(try response.requireResult() == Profile(nickname: "애니픽"))
    }

    @Test("업무 에러 코드는 던지지 않고 그대로 돌려준다")
    func returnsBusinessErrorCode() async throws {
        server.reply(
            .json(status: 200, body: #"{"code":132,"value":"FAIL","errorValue":"탈퇴한 회원입니다."}"#)
        )

        let response = try await client.send(
            Endpoint<Profile>(method: .post, path: "api/oauth/kakao/callback", requiresAuth: false)
        )

        #expect(response.code == 132)
        #expect(response.errorValue == "탈퇴한 회원입니다.")
        #expect(response.result == nil)
        #expect(throws: TransportError.decoding) { try response.requireResult() }
    }

    @Test("2xx가 아니면 상태 코드를 담아 던진다")
    func throwsServerStatus() async {
        server.reply(.json(status: 500, body: #"{"code":500,"value":"ERROR"}"#))

        await #expect(throws: TransportError.server(status: 500)) {
            try await client.send(
                Endpoint<EmptyResult>(method: .get, path: "api/x", requiresAuth: false))
        }
    }

    @Test("sendRaw는 HTTP 상태와 무관하게 본문을 그대로 돌려준다")
    func returnsRawBody() async throws {
        server.reply(.json(status: 404, body: "not json"))

        let data = try await client.sendRaw(
            Endpoint<EmptyResult>(method: .get, path: "api/image/3", requiresAuth: false))

        #expect(String(decoding: data, as: UTF8.self) == "not json")
    }

    @Test("응답 형식이 다르면 decoding 에러")
    func throwsDecodingError() async {
        server.reply(.json(status: 200, body: #"{"unexpected":true}"#))

        await #expect(throws: TransportError.decoding) {
            try await client.send(
                Endpoint<EmptyResult>(method: .get, path: "api/x", requiresAuth: false))
        }
    }

    @Test(
        "URLError를 TransportError로 바꾼다",
        arguments: [
            (URLError.Code.notConnectedToInternet, TransportError.offline),
            (.networkConnectionLost, .offline),
            (.dataNotAllowed, .offline),
            (.timedOut, .timeout),
            (.cancelled, .cancelled),
            (.badServerResponse, .unknown),
        ]
    )
    func mapsURLError(code: URLError.Code, expected: TransportError) async {
        server.reply(.failure(code))

        await #expect(throws: expected) {
            try await client.send(
                Endpoint<EmptyResult>(method: .get, path: "api/x", requiresAuth: false))
        }
    }

    @Test("Task가 취소되면 요청하지 않고 cancelled")
    func mapsTaskCancellation() async {
        server.reply(.json(status: 200, body: #"{"code":200,"value":"OK"}"#))
        let client = self.client

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await client.send(
                Endpoint<EmptyResult>(method: .get, path: "api/x", requiresAuth: false)
            )
        }

        await #expect(throws: TransportError.cancelled) { try await task.value }
        #expect(server.requests.isEmpty)
    }
}

@Suite("HTTPClient 토큰 만료")
struct HTTPClientTokenTests {
    let server = StubServer()
    private let expired = StubServer.Reply.json(
        status: 401, body: #"{"code":119,"value":"EXPIRED"}"#)
    private let success = StubServer.Reply.json(status: 200, body: #"{"code":200,"value":"OK"}"#)

    @Test("119를 받으면 토큰을 갱신하고 새 토큰으로 1회 재시도한다")
    func refreshesAndRetries() async throws {
        server.reply(expired, success)
        let provider = FakeTokenProvider(token: "old", refreshedToken: "new")
        let client = HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: provider)

        let response = try await client.send(
            Endpoint<EmptyResult>(method: .get, path: "api/me", requiresAuth: true)
        )

        #expect(response.code == 200)
        #expect(await provider.refreshCount == 1)
        #expect(
            server.requests.map { $0.value(forHTTPHeaderField: "Authorization") } == [
                "Bearer old", "Bearer new",
            ])
    }

    @Test("갱신에 실패하면 sessionExpired, 재시도하지 않는다")
    func throwsWhenRefreshFails() async {
        server.reply(expired)
        let provider = FakeTokenProvider(token: "old", refreshError: .sessionExpired)
        let client = HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: provider)

        await #expect(throws: TransportError.sessionExpired) {
            try await client.send(
                Endpoint<EmptyResult>(method: .get, path: "api/me", requiresAuth: true))
        }
        #expect(server.requests.count == 1)
    }

    @Test("재시도도 119면 sessionExpired, 더 반복하지 않는다")
    func doesNotRetryTwice() async {
        server.reply(expired)
        let provider = FakeTokenProvider(token: "old", refreshedToken: "new")
        let client = HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: provider)

        await #expect(throws: TransportError.sessionExpired) {
            try await client.send(
                Endpoint<EmptyResult>(method: .get, path: "api/me", requiresAuth: true))
        }
        #expect(server.requests.count == 2)
        #expect(await provider.refreshCount == 1)
    }

    @Test("인증이 필요 없는 요청은 119여도 갱신하지 않는다")
    func doesNotRefreshForPublicEndpoint() async {
        server.reply(expired)
        let provider = FakeTokenProvider(token: "old", refreshedToken: "new")
        let client = HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: provider)

        await #expect(throws: TransportError.server(status: 401)) {
            try await client.send(
                Endpoint<EmptyResult>(method: .post, path: "api/users/login", requiresAuth: false))
        }
        #expect(await provider.refreshCount == 0)
    }

    @Test("토큰이 없으면 요청하지 않고 sessionExpired", arguments: [nil, ""])
    func throwsWithoutToken(token: String?) async {
        server.reply(success)
        let client = HTTPClient(
            baseURL: server.baseURL,
            configuration: server.configuration,
            tokenProvider: FakeTokenProvider(token: token)
        )

        await #expect(throws: TransportError.sessionExpired) {
            try await client.send(
                Endpoint<EmptyResult>(method: .get, path: "api/me", requiresAuth: true))
        }
        #expect(server.requests.isEmpty)
    }

    @Test("인증 없는 클라이언트로 인증 요청을 보내면 sessionExpired")
    func throwsWithoutTokenProvider() async {
        server.reply(success)
        let client = HTTPClient(
            baseURL: server.baseURL, configuration: server.configuration, tokenProvider: nil)

        await #expect(throws: TransportError.sessionExpired) {
            try await client.send(
                Endpoint<EmptyResult>(method: .get, path: "api/me", requiresAuth: true))
        }
        #expect(server.requests.isEmpty)
    }
}

@Suite("multipart")
struct MultipartTests {
    @Test("RFC 7578 형식으로 인코딩한다")
    func encodesForm() {
        var form = MultipartForm(boundary: "B")
        form.addField(name: "title", value: "제목")
        form.addFile(
            name: "postImageFile", fileName: "a.jpg", mimeType: "image/jpeg",
            data: Data([0x01, 0x02]))

        var expected = Data()
        expected.append(
            Data("--B\r\nContent-Disposition: form-data; name=\"title\"\r\n\r\n제목\r\n".utf8))
        expected.append(
            Data(
                "--B\r\nContent-Disposition: form-data; name=\"postImageFile\"; filename=\"a.jpg\"\r\n"
                    .utf8
            )
        )
        expected.append(Data("Content-Type: image/jpeg\r\n\r\n".utf8))
        expected.append(Data([0x01, 0x02]))
        expected.append(Data("\r\n--B--\r\n".utf8))

        #expect(form.encoded() == expected)
        #expect(form.contentType == "multipart/form-data; boundary=B")
    }

    @Test("multipart 요청은 boundary가 담긴 Content-Type과 인코딩된 본문으로 올린다")
    func uploadsForm() async throws {
        let server = StubServer()
        server.reply(.json(status: 200, body: #"{"code":200,"value":"OK"}"#))
        let client = HTTPClient(
            baseURL: server.baseURL,
            configuration: server.configuration,
            tokenProvider: FakeTokenProvider(token: "access-1")
        )
        var form = MultipartForm(boundary: "B")
        form.addFile(
            name: "profileImageFile", fileName: "profile.jpg", mimeType: "image/jpeg",
            data: Data([0xFF]))

        _ = try await client.send(
            Endpoint<EmptyResult>(
                method: .post,
                path: "api/image/profile-image",
                body: .multipart(form),
                requiresAuth: true
            )
        )

        let request = try #require(server.requests.first)
        #expect(
            request.value(forHTTPHeaderField: "Content-Type") == "multipart/form-data; boundary=B")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer access-1")
        #expect(server.bodies.first == form.encoded())
    }
}
