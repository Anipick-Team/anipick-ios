//
//  DeepLinkTests.swift
//  AniPickTests
//

import DetailInterface
import ExploreInterface
import HomeInterface
import SwiftUI
import Testing
@testable import AniPick

struct DeepLinkParsingTests {

    @Test(arguments: [
        ("https://anipick.p-e.kr/app/community/post/123", DeepLink.communityPost(id: 123)),
        ("anipick://app/community/post/123", .communityPost(id: 123)),
        ("https://anipick.p-e.kr/app/anime/detail/45", .anime(id: 45)),
        ("anipick://app/anime/detail/45", .anime(id: 45)),
        ("anipick://anime/45", .anime(id: 45)),
        ("anipick://producer/7", .producer(id: 7)),
    ])
    func 지원하는_경로를_해석한다(urlString: String, expected: DeepLink) throws {
        let url = try #require(URL(string: urlString))
        #expect(DeepLink(url: url) == expected)
    }

    @Test(arguments: [
        "https://anipick.p-e.kr/app/community/post/abc",
        "https://anipick.p-e.kr/app/community/post",
        "https://anipick.p-e.kr/app/community/123",
        "https://anipick.p-e.kr/community/post/123",
        "https://example.com/app/community/post/123",
        "anipick://app/community/comment/123",
        "kakao0342f72c46d8653e8a501fe5704a540c://oauth?code=abc",
    ])
    func 지원하지_않는_경로는_unknown이다(urlString: String) throws {
        let url = try #require(URL(string: urlString))
        #expect(DeepLink(url: url) == .unknown)
    }

    @Test func 게시글_공유_링크는_안드로이드와_같은_경로다() {
        #expect(
            DeepLink.communityPost(id: 123).universalLink?.absoluteString
                == "https://anipick.p-e.kr/app/community/post/123"
        )
    }

    @Test(arguments: [DeepLink.communityPost(id: 9), .anime(id: 9)])
    func 공유_링크를_다시_해석하면_같은_딥링크다(link: DeepLink) throws {
        let url = try #require(link.universalLink)
        #expect(DeepLink(url: url) == link)
    }
}

struct DeepLinkTargetTests {
    @Test(arguments: [
        (DeepLink.anime(id: 45), DeepLinkTarget.detail(.anime(id: 45))),
        (.communityPost(id: 123), .explore(.communityPost(id: 123))),
    ])
    func 딥링크는_Feature_화면으로_간다(link: DeepLink, expected: DeepLinkTarget) {
        #expect(DeepLinkTarget.target(for: link) == expected)
    }

    @Test(arguments: [DeepLink.producer(id: 7), .unknown])
    func 제작사와_알_수_없는_링크는_이동하지_않는다(link: DeepLink) {
        #expect(DeepLinkTarget.target(for: link) == nil)
    }
}

@MainActor
struct AppStateDeepLinkTests {

    /// 이동은 기다림 없이 바로 일어난다 (Phase 4-1). 늦게 일어나는 이동이 없는지 잠시 본다
    private func waitForNavigation() async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    @Test func 지연_없이_바로_이동하고_쌓여_있던_화면은_비운다() {
        let navigationManager = NavigationManager()
        navigationManager.isLoggedIn = true
        navigationManager.path.append(HomeRoute.search)
        let appState = AppState(navigationManager: navigationManager)

        appState.deepLink = .anime(id: 45)

        #expect(navigationManager.path == NavigationPath([DetailRoute.anime(id: 45)]))
    }

    @Test func 로그인_상태면_게시글_상세로_이동한다() async throws {
        let navigationManager = NavigationManager()
        navigationManager.isLoggedIn = true
        let appState = AppState(navigationManager: navigationManager)

        appState.deepLink = .communityPost(id: 123)
        try await waitForNavigation()

        #expect(navigationManager.path == NavigationPath([ExploreRoute.communityPost(id: 123)]))
        #expect(appState.pendingDeepLink == nil)
    }

    @Test func 로그인_전이면_이동하지_않고_보관한다() async throws {
        let navigationManager = NavigationManager()
        navigationManager.isLoggedIn = false
        let appState = AppState(navigationManager: navigationManager)

        appState.deepLink = .communityPost(id: 123)
        try await waitForNavigation()

        #expect(navigationManager.path.isEmpty)
        #expect(appState.pendingDeepLink == .communityPost(id: 123))
    }

    @Test func 로그인하면_보관한_딥링크로_이동한다() async throws {
        let navigationManager = NavigationManager()
        navigationManager.isLoggedIn = false
        let appState = AppState(navigationManager: navigationManager)
        appState.deepLink = .communityPost(id: 123)

        navigationManager.completeLogin()
        try await waitForNavigation()

        #expect(navigationManager.path == NavigationPath([ExploreRoute.communityPost(id: 123)]))
        #expect(appState.pendingDeepLink == nil)
    }

    @Test func 알_수_없는_링크는_보관한_딥링크를_덮어쓰지_않는다() async throws {
        let navigationManager = NavigationManager()
        navigationManager.isLoggedIn = false
        let appState = AppState(navigationManager: navigationManager)
        appState.deepLink = .communityPost(id: 123)

        // 카카오 로그인 콜백 URL이 onOpenURL로 들어오는 경우
        appState.deepLink = .unknown

        #expect(appState.pendingDeepLink == .communityPost(id: 123))
    }
}
