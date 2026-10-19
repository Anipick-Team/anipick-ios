//
//  EditNicknameEquivalenceTests.swift
//  AniPickTests
//
//  이관한 닉네임 변경 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R 반복 1).
//

import Foundation
import Navigation
import Networking
import SettingFeature
import SettingInterface
import Storage
import SwiftUI
import Testing
import UserClientLive

@testable import AniPick

@MainActor
@Suite("닉네임 변경 화면 ↔ 레거시", .serialized)
struct EditNicknameEquivalenceTests {
    private let screen = CGSize(width: 393, height: 852)

    private func pixels(_ view: some View) throws -> Data {
        // NavigationStack으로 감싸면 ImageRenderer가 내용을 그리지 않는다 (통제 테스트로 확인)
        let renderer = ImageRenderer(content: view.frame(width: screen.width, height: screen.height))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        return try #require(image.dataProvider?.data as Data?)
    }

    private func newScreen() -> some View {
        let builder = SettingBuilder(
            dependencies: SettingDependencies(
                userClient: LiveUserClient(
                    client: HTTPClientStub.client,
                    preferences: Preferences()
                ),
                navigator: LegacyNavigator(navigationManager: NavigationManager())
            )
        )
        return builder.make(.editNickname)
    }

    @Test("저장된 닉네임이 있을 때·없을 때 모두 같다", arguments: ["애니픽", nil])
    func matchesLegacy(nickname: String?) throws {
        let defaults = UserDefaults.standard
        let original = defaults.object(forKey: "nickname")
        defer { defaults.set(original, forKey: "nickname") }
        defaults.set(nickname, forKey: "nickname")

        let legacy = try pixels(
            EditNicknameView(viewModel: EditNicknameViewModel(navigationManager: NavigationManager()))
        )
        let new = try pixels(newScreen())

        #expect(legacy == new)
    }

    @Test("통제: 닉네임이 다르면 픽셀이 다르다")
    func detectsDifference() throws {
        let defaults = UserDefaults.standard
        let original = defaults.object(forKey: "nickname")
        defer { defaults.set(original, forKey: "nickname") }

        defaults.set("애니픽", forKey: "nickname")
        let legacy = try pixels(
            EditNicknameView(viewModel: EditNicknameViewModel(navigationManager: NavigationManager()))
        )
        defaults.set("다른닉", forKey: "nickname")
        let new = try pixels(newScreen())

        #expect(legacy != new)
    }
}

/// 렌더링만 하므로 요청을 보내지 않는다
private enum HTTPClientStub {
    static let client = Networking.HTTPClient(baseURL: URL(string: "https://example.invalid/")!, tokenProvider: nil)
}
