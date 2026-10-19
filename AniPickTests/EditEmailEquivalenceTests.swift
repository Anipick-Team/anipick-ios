//
//  EditEmailEquivalenceTests.swift
//  AniPickTests
//
//  이관한 이메일 변경 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R 반복 4).
//

import AuthClientLive
import Foundation
import Navigation
import Networking
import SwiftUI
import Testing
import UserClientLive

@testable import AniPick
@testable import SettingFeature

@MainActor
@Suite("이메일 변경 화면 ↔ 레거시", .serialized)
struct EditEmailEquivalenceTests {
    private func pixels(_ view: some View) throws -> Data {
        // NavigationStack으로 감싸면 ImageRenderer가 내용을 그리지 않는다
        let renderer = ImageRenderer(content: view.frame(width: 393, height: 852))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        return try #require(image.dataProvider?.data as Data?)
    }

    private var reducer: EditEmailReducer {
        let http = HTTPClient(baseURL: URL(string: "https://example.invalid/")!, tokenProvider: nil)
        return EditEmailReducer(
            userClient: LiveUserClient(client: http),
            authClient: LiveAuthClient(client: http, onLoggedOut: {}),
            navigator: LegacyNavigator(navigationManager: NavigationManager())
        )
    }

    private func legacyPixels(email: String) throws -> Data {
        let defaults = UserDefaults.standard
        let original = defaults.object(forKey: "email")
        defer { defaults.set(original, forKey: "email") }
        defaults.set(email, forKey: "email")
        return try pixels(AniPick.EditEmailView(viewModel: EditEmailViewModel(navigationManager: NavigationManager())))
    }

    @Test("처음 화면이 같다")
    func matchesLegacy() throws {
        let new = SettingFeature.EditEmailView(state: .init(currentEmail: "ani@pick.com"), reducer: reducer)

        #expect(try legacyPixels(email: "ani@pick.com") == pixels(new))
    }

    @Test("완료 팝업이 뜬 화면도 같다 (레거시는 팝업 상태를 직접 켠다)")
    func matchesLegacyWithCompletionPopup() throws {
        let defaults = UserDefaults.standard
        let original = defaults.object(forKey: "email")
        defer { defaults.set(original, forKey: "email") }
        defaults.set("ani@pick.com", forKey: "email")
        let viewModel = EditEmailViewModel(navigationManager: NavigationManager())
        viewModel.isShowEditEmailPopup = true
        var state = EditEmailReducer.State(currentEmail: "ani@pick.com")
        state.isCompletionPresented = true

        let legacy = try pixels(AniPick.EditEmailView(viewModel: viewModel))
        let new = try pixels(SettingFeature.EditEmailView(state: state, reducer: reducer))

        #expect(legacy == new)
    }

    @Test("통제: 오류 문구가 있으면 픽셀이 다르다")
    func detectsDifference() throws {
        var state = EditEmailReducer.State(currentEmail: "ani@pick.com")
        state.emailError = "에러 발생"
        let new = SettingFeature.EditEmailView(state: state, reducer: reducer)

        #expect(try legacyPixels(email: "ani@pick.com") != pixels(new))
    }
}
