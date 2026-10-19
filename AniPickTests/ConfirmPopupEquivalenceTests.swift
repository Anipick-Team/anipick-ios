//
//  ConfirmPopupEquivalenceTests.swift
//  AniPickTests
//
//  DesignSystem의 ConfirmPopup이 레거시 Setting 팝업과 같은 모양인지 픽셀로 비교한다 (이관 2-3).
//

import DesignSystem
import SwiftUI
import Testing

@testable import AniPick

@MainActor
@Suite("ConfirmPopup ↔ 레거시 팝업")
struct ConfirmPopupEquivalenceTests {
    private let screen = CGSize(width: 393, height: 852)

    private func pixels(_ view: some View) throws -> Data {
        let renderer = ImageRenderer(content: view.frame(width: screen.width, height: screen.height))
        renderer.scale = 2
        let image = try #require(renderer.cgImage)
        let data = try #require(image.dataProvider?.data as Data?)
        return data
    }

    private func newPopup(_ popup: ConfirmPopup) -> some View {
        return Color.clear.popup(isPresented: true) { popup }
    }

    @Test("SNS 가입 안내 팝업과 같다")
    func matchesSNSSignupPopup() throws {
        let legacy = try pixels(SNSSignupPopupView(cancelAction: {}, okAction: {}))
        let new = try pixels(
            newPopup(
                ConfirmPopup(
                    title: "SNS로 간편 가입된 계정입니다.",
                    message: "SNS로 로그인해주세요.",
                    cancelTitle: "닫기",
                    confirmTitle: "SNS로 로그인"
                ) {}
            )
        )

        #expect(legacy == new)
    }

    @Test("이메일 변경 완료 팝업(버튼 1개)과 같다")
    func matchesEditEmailPopup() throws {
        let legacy = try pixels(EditEmailPopupView(okAction: {}))
        let new = try pixels(
            newPopup(
                ConfirmPopup(
                    title: "이메일 변경이 완료되었어요.",
                    message: "변경된 이메일로 다시 로그인해 주세요.",
                    cancelTitle: nil,
                    confirmTitle: "확인"
                ) {}
            )
        )

        #expect(legacy == new)
    }

    @Test("통제: 문구가 다르면 픽셀이 다르다")
    func detectsDifference() throws {
        let legacy = try pixels(EditEmailPopupView(okAction: {}))
        let new = try pixels(
            newPopup(
                ConfirmPopup(
                    title: "이메일 변경이 완료되었어요!",
                    message: "변경된 이메일로 다시 로그인해 주세요.",
                    cancelTitle: nil,
                    confirmTitle: "확인"
                ) {}
            )
        )

        #expect(legacy != new)
    }
}
