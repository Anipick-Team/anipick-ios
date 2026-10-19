//
//  EditPasswordEquivalenceTests.swift
//  AniPickTests
//
//  이관한 비밀번호 변경 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R 반복 3).
//

import Foundation
import Navigation
import Networking
import SettingInterface
import SwiftUI
import Testing
import UserClientLive

@testable import AniPick
@testable import SettingFeature

@MainActor
@Suite("비밀번호 변경 화면 ↔ 레거시")
struct EditPasswordEquivalenceTests {
    private func pixels(_ view: some View) throws -> Data {
        // NavigationStack으로 감싸면 ImageRenderer가 내용을 그리지 않는다
        let renderer = ImageRenderer(content: view.frame(width: 393, height: 852))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        return try #require(image.dataProvider?.data as Data?)
    }

    private var reducer: EditPasswordReducer {
        return EditPasswordReducer(
            userClient: LiveUserClient(
                client: HTTPClient(baseURL: URL(string: "https://example.invalid/")!, tokenProvider: nil)
            ),
            navigator: LegacyNavigator(navigationManager: NavigationManager())
        )
    }

    private var legacy: some View {
        return AniPick.EditPasswordView(viewModel: EditPasswordViewModel(navigationManager: NavigationManager()))
    }

    @Test("처음 화면이 같다")
    func matchesLegacy() throws {
        let new = SettingFeature.EditPasswordView(state: EditPasswordReducer.State(), reducer: reducer)

        #expect(try pixels(legacy) == pixels(new))
    }

    @Test("통제: 오류 문구가 있으면 픽셀이 다르다")
    func detectsDifference() throws {
        var state = EditPasswordReducer.State()
        state.confirmationError = "비밀번호가 일치하지 않습니다."
        let new = SettingFeature.EditPasswordView(state: state, reducer: reducer)

        #expect(try pixels(legacy) != pixels(new))
    }
}
