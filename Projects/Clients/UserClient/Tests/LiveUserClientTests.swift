import ClientCore
import Foundation
import Networking
import Storage
import Testing

@testable import UserClientInterface
@testable import UserClientLive

/// 레거시 `BaseResponse`와 같은 모양
private struct Envelope: Decodable {
    let code: Int
    let value: String
    let errorValue: String?
}

/// fixture는 레거시 `BaseResponse`로 만든 합성 JSON이다 (실제 응답 수집은 미룬 작업, 이관 Q11).
@Suite("LiveUserClient")
struct LiveUserClientTests {
    @Test("닉네임 변경 요청: PATCH api/setting/nickname, 본문 nickname, 인증 필요")
    func buildsEditNicknameEndpoint() throws {
        let endpoint = LiveUserClient.editNicknameEndpoint("새닉")

        #expect(endpoint.method == .patch)
        #expect(endpoint.path == "api/setting/nickname")
        #expect(endpoint.requiresAuth)
        guard case .json(let body) = endpoint.body else {
            Issue.record("JSON 본문이 아니다")
            return
        }
        let encoded = try JSONEncoder().encode(body)
        #expect(
            try JSONSerialization.jsonObject(with: encoded) as? [String: String] == [
                "nickname": "새닉"
            ])
    }

    @Test(
        "결과 코드를 의미로 바꾼다",
        arguments: [
            (200, nil), (117, EditNicknameError.duplicated), (116, .invalidFormat), (118, .empty),
            (500, .unexpectedResponse),
        ]
    )
    func mapsResultCode(code: Int, expected: EditNicknameError?) {
        let result = LiveUserClient.editNicknameResult(code: code)

        switch result {
        case .success:
            #expect(expected == nil)
        case .failure(let error):
            #expect(error == expected)
        }
    }

    @Test(
        "fixture를 서버 응답 형식으로 읽어 결과 코드를 얻는다",
        arguments: [("edit-nickname-success", 200), ("edit-nickname-duplicated", 117)])
    func decodesFixture(name: String, code: Int) throws {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json"))
        let envelope = try JSONDecoder().decode(Envelope.self, from: Data(contentsOf: url))

        #expect(envelope.code == code)
    }

    @Test("비밀번호 변경 요청: PATCH api/setting/password, 본문 3개")
    func buildsEditPasswordEndpoint() throws {
        let endpoint = LiveUserClient.editPasswordEndpoint(
            current: "c", new: "n", confirmation: "k")

        #expect(endpoint.method == .patch)
        #expect(endpoint.path == "api/setting/password")
        #expect(endpoint.requiresAuth)
        guard case .json(let body) = endpoint.body else {
            Issue.record("JSON 본문이 아니다")
            return
        }
        let encoded = try JSONEncoder().encode(body)
        #expect(
            try JSONSerialization.jsonObject(with: encoded) as? [String: String]
                == ["currentPassword": "c", "newPassword": "n", "confirmNewPassword": "k"]
        )
    }

    @Test(
        "비밀번호 변경 결과 코드를 의미로 바꾼다",
        arguments: [
            (200, nil), (107, EditPasswordError.currentPasswordMismatch),
            (108, .confirmationMismatch),
            (500, .unexpectedResponse),
        ]
    )
    func mapsEditPasswordCode(code: Int, expected: EditPasswordError?) {
        switch LiveUserClient.editPasswordResult(code: code) {
        case .success:
            #expect(expected == nil)
        case .failure(let error):
            #expect(error == expected)
        }
    }

    @Test("저장된 닉네임이 없으면 \"--\", 있으면 그 값 (레거시 UserDefaults 키 nickname)")
    func readsCachedNickname() throws {
        let suiteName = "UserClientTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let client = LiveUserClient(
            client: HTTPClient(baseURL: URL(string: "https://example.com/")!, tokenProvider: nil),
            preferences: Preferences(defaults: defaults)
        )

        #expect(client.cachedNickname() == "--")
        defaults.set("애니픽", forKey: "nickname")
        #expect(client.cachedNickname() == "애니픽")
    }
}
