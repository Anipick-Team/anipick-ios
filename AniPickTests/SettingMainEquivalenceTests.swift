//
//  SettingMainEquivalenceTests.swift
//  AniPickTests
//
//  이관한 설정 메인 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R 반복 5).
//

import AuthClientLive
import Foundation
import Navigation
import Networking
import SwiftUI
import UIKit
import Testing
import UserClientLive

@testable import AniPick
@testable import SettingFeature

@MainActor
@Suite("설정 메인 화면 ↔ 레거시", .serialized)
struct SettingMainEquivalenceTests {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    /// ImageRenderer는 ScrollView 내용을 그리지 않는다(통제 테스트로 확인). 창에 올려 UIKit으로 그린다.
    /// `onAppear`도 실행된다 — 레거시·새 화면 모두 저장된 닉네임·이메일을 읽는다.
    private func pixels(_ view: some View) throws -> Data {
        let bounds = CGRect(x: 0, y: 0, width: 393, height: 852)
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        controller.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
            controller.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        return try #require(image.pngData())
    }

    private var reducer: SettingReducer {
        let http = HTTPClient(baseURL: URL(string: "https://example.invalid/")!, tokenProvider: nil)
        return SettingReducer(
            userClient: LiveUserClient(client: http),
            authClient: LiveAuthClient(client: http, onLoggedOut: {}),
            navigator: LegacyNavigator(navigationManager: NavigationManager()),
            openURL: { _ in }
        )
    }

    /// 레거시는 ViewModel·View를 만들 때 저장된 `sns`를 읽는다
    private func withSNS<T>(_ sns: String?, _ body: () throws -> T) rethrows -> T {
        let defaults = UserDefaults.standard
        let original = defaults.object(forKey: "sns")
        defer { defaults.set(original, forKey: "sns") }
        defaults.set(sns, forKey: "sns")
        return try body()
    }

    private func legacy(showsLogoutPopup: Bool = false) -> some View {
        let viewModel = SettingViewModel(navigationManager: NavigationManager())
        viewModel.isShowLogoutPopup = showsLogoutPopup
        return AniPick.SettingView(viewModel: viewModel)
    }

    private func new(sns: String, showsLogoutPopup: Bool = false) -> some View {
        var state = SettingReducer.State(snsAccount: sns, appVersion: appVersion)
        state.isLogoutPopupPresented = showsLogoutPopup
        return SettingFeature.SettingView(state: state, reducer: reducer)
    }

    @Test("처음 화면이 같다 (이메일 가입·카카오 가입)", arguments: ["", "KAKAO"])
    func matchesLegacy(sns: String) throws {
        let (legacyPixels, newPixels) = try withSNS(sns.isEmpty ? nil : sns) {
            return (try pixels(legacy()), try pixels(new(sns: sns)))
        }

        #expect(legacyPixels == newPixels)
    }

    @Test("로그아웃 팝업이 뜬 화면이 같다 (ConfirmPopup .compact ↔ LogoutPopupView)")
    func matchesLegacyWithLogoutPopup() throws {
        let (legacyPixels, newPixels) = try withSNS(nil) {
            return (
                try pixels(legacy(showsLogoutPopup: true)),
                try pixels(new(sns: "", showsLogoutPopup: true))
            )
        }

        #expect(legacyPixels == newPixels)
    }

    @Test("통제: 팝업이 있으면 픽셀이 다르다")
    func detectsPopup() throws {
        let (withPopup, withoutPopup) = try withSNS(nil) {
            return (try pixels(new(sns: "", showsLogoutPopup: true)), try pixels(new(sns: "")))
        }

        #expect(withPopup != withoutPopup)
    }

    @Test("통제: SNS 가입 여부가 다르면 픽셀이 다르다")
    func detectsDifference() throws {
        let (legacyPixels, newPixels) = try withSNS(nil) {
            return (try pixels(legacy()), try pixels(new(sns: "KAKAO")))
        }

        #expect(legacyPixels != newPixels)
    }
}
