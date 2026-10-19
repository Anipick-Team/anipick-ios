//
//  WithdrawalEquivalenceTests.swift
//  AniPickTests
//
//  이관한 회원 탈퇴 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R 반복 2).
//

import AuthClientLive
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
@Suite("회원 탈퇴 화면 ↔ 레거시", .serialized)
struct WithdrawalEquivalenceTests {
    private func pixels(_ view: some View) throws -> Data {
        // NavigationStack으로 감싸면 ImageRenderer가 내용을 그리지 않는다
        let renderer = ImageRenderer(content: view.frame(width: 393, height: 852))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        return try #require(image.dataProvider?.data as Data?)
    }

    private func screens(email: String?) throws -> (legacy: Data, new: Data) {
        let defaults = UserDefaults.standard
        let original = defaults.object(forKey: "email")
        defer { defaults.set(original, forKey: "email") }
        defaults.set(email, forKey: "email")

        let legacy = try pixels(WithdrawalView(viewModel: WithdrawalViewModel(navigationManager: NavigationManager())))
        let builder = SettingBuilder(
            dependencies: SettingDependencies(
                userClient: LiveUserClient(
                    client: HTTPClient(baseURL: URL(string: "https://example.invalid/")!, tokenProvider: nil)
                ),
                authClient: LiveAuthClient(client: HTTPClient(baseURL: URL(string: "https://example.invalid/")!, tokenProvider: nil), onLoggedOut: {}),
                navigator: LegacyNavigator(navigationManager: NavigationManager())
            )
        )
        return (legacy, try pixels(builder.make(.withdrawal)))
    }

    @Test("이메일이 있을 때·없을 때 모두 같다", arguments: ["ani@pick.com", nil])
    func matchesLegacy(email: String?) throws {
        let (legacy, new) = try screens(email: email)

        #expect(legacy == new)
    }

    @Test("통제: 이메일이 다르면 픽셀이 다르다")
    func detectsDifference() throws {
        let (legacy, _) = try screens(email: "ani@pick.com")
        let (_, new) = try screens(email: "other@pick.com")

        #expect(legacy != new)
    }
}
