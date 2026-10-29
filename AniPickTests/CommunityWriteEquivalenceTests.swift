//
//  CommunityWriteEquivalenceTests.swift
//  AniPickTests
//
//  이관한 커뮤니티 글쓰기가 레거시와 같은 모양인지 픽셀로 비교한다 (R Explore 3).
//  레거시는 입력값을 private @State로 들고 있어, 처음 값(새 글·수정 진입)만 비교할 수 있다.
//

import CommunityClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import ExploreFeature

@MainActor
@Suite("커뮤니티 글쓰기 ↔ 레거시", .serialized)
struct CommunityWriteEquivalenceTests {
    struct Setup: Sendable {
        var postId: Int?
        var title = ""
        var content = ""
        var isSpoiler = false
    }

    private func legacy(_ setup: Setup) -> some View {
        return AniPick.CommunityWriteView(
            seriesId: 1, animeTitle: "애니", postId: setup.postId, initialTitle: setup.title,
            initialContent: setup.content, initialIsSpoiler: setup.isSpoiler)
    }

    private func new(_ setup: Setup) -> some View {
        let client = MockCommunityClient()
        return ExploreFeature.CommunityWriteView(
            state: CommunityWriteReducer.State(
                seriesId: 1, postId: setup.postId, title: setup.title, content: setup.content,
                isSpoiler: setup.isSpoiler),
            reducer: CommunityWriteReducer(
                communityClient: client, navigator: LegacyNavigator(navigationManager: NavigationManager()),
                loadPhoto: { _ in nil }, postUpdated: { _ in }),
            imageURL: client.imageURL(id:))
    }

    @Test(
        "새 글·수정 진입 화면이 같다",
        arguments: [
            Setup(), Setup(title: "   "),
            Setup(postId: 3, title: "제목입니다", content: "첫 줄\n둘째 줄", isSpoiler: true),
            Setup(postId: 3, title: "t", content: String(repeating: "가", count: 120)),
        ]
    )
    func states(setup: Setup) throws {
        #expect(try hostedSnapshot(legacy(setup)) == hostedSnapshot(new(setup)))
    }

    @Test("통제: 내용 길이(글자 수)가 다르면 픽셀이 다르다")
    func detectsCount() throws {
        #expect(
            try hostedSnapshot(legacy(Setup(postId: 3, title: "t", content: "ab")))
                != hostedSnapshot(new(Setup(postId: 3, title: "t", content: "abc"))))
    }

    @Test("통제: 새 글과 수정은 픽셀이 다르다")
    func detectsMode() throws {
        #expect(try hostedSnapshot(legacy(Setup(title: "t"))) != hostedSnapshot(new(Setup(postId: 3, title: "t"))))
    }
}
