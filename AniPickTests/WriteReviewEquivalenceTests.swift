//
//  WriteReviewEquivalenceTests.swift
//  AniPickTests
//
//  이관한 리뷰 작성 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R Review 1).
//

import FeatureTestSupport
import Foundation
import Navigation
import Networking
import ReviewClientLive
import SwiftUI
import Testing

@testable import AniPick
@testable import ReviewFeature

@MainActor
@Suite("리뷰 작성 화면 ↔ 레거시", .serialized)
struct WriteReviewEquivalenceTests {
    private func legacy(rating: Double, content: String, isSpoiler: Bool = false) -> some View {
        let viewModel = WriteReviewViewModel(
            navigationManager: NavigationManager(),
            starRating: rating,
            animeId: 1,
            reviewContent: content
        )
        viewModel.isSpoiler = isSpoiler
        return AniPick.WriteReviewView(viewModel: viewModel)
    }

    private func new(rating: Double, content: String, isSpoiler: Bool = false) -> some View {
        var state = WriteReviewReducer.State(animeId: 1, rating: rating, content: content)
        state.isSpoiler = isSpoiler
        let reducer = WriteReviewReducer(
            reviewClient: LiveReviewClient(
                client: HTTPClient(baseURL: URL(string: "https://example.invalid/")!, tokenProvider: nil)
            ),
            navigator: LegacyNavigator(navigationManager: NavigationManager()),
            analytics: RecordingTracker(),
            openURL: { _ in },
            onReviewWritten: {}
        )
        return ReviewFeature.WriteReviewView(state: state, reducer: reducer)
    }

    @Test(
        "작성·수정·스포일러 켬 화면이 같다",
        arguments: [
            (0.0, "", false), (3.5, "", false), (4.0, "다시 봐도 재밌는 작품", false),
            (5.0, "스포일러 있는 리뷰", true),
        ]
    )
    func matchesLegacy(rating: Double, content: String, isSpoiler: Bool) throws {
        let legacyPixels = try hostedSnapshot(legacy(rating: rating, content: content, isSpoiler: isSpoiler))
        let newPixels = try hostedSnapshot(new(rating: rating, content: content, isSpoiler: isSpoiler))

        #expect(legacyPixels == newPixels)
    }

    @Test("통제: 글자 수가 같은 다른 내용이면 픽셀이 다르다 (입력창 UITextView가 그려진다)")
    func detectsEditorText() throws {
        let legacyPixels = try hostedSnapshot(legacy(rating: 3, content: "가나다"))
        let newPixels = try hostedSnapshot(new(rating: 3, content: "라마바"))

        #expect(legacyPixels != newPixels)
    }

    @Test("통제: 별점이 다르면 픽셀이 다르다")
    func detectsRating() throws {
        let legacyPixels = try hostedSnapshot(legacy(rating: 3, content: ""))
        let newPixels = try hostedSnapshot(new(rating: 3.5, content: ""))

        #expect(legacyPixels != newPixels)
    }
}
