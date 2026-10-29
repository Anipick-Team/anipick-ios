//
//  CommunityPostEquivalenceTests.swift
//  AniPickTests
//
//  이관한 커뮤니티 게시글 상세가 레거시와 같은 모양인지 픽셀로 비교한다 (R Explore 5).
//  레거시는 ViewModel을 안에서 만들어(@StateObject private) 데이터를 넣을 수 없다. 처음 화면(불러오는 중)만 비교한다.
//  레거시는 만들 때 운영 서버에 상세·댓글을 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//

import Combine
import CommunityClientTesting
import Navigation
import SwiftUI
import Testing

@testable import AniPick
@testable import ExploreFeature

@MainActor
@Suite("커뮤니티 게시글 상세 ↔ 레거시", .serialized)
struct CommunityPostEquivalenceTests {
    private func legacy() -> some View {
        return AniPick.CommunityDetailView(postId: 999_999)
            .environmentObject(NavigationManager())
    }

    private func new(isLoading: Bool = true) -> some View {
        var state = CommunityPostReducer.State(postId: 999_999)
        state.isLoading = isLoading
        state.didStart = true
        return ExploreFeature.CommunityPostView(
            state: state,
            reducer: CommunityPostReducer(
                communityClient: MockCommunityClient(),
                navigator: LegacyNavigator(navigationManager: NavigationManager()), share: { _ in }),
            postUpdates: Empty().eraseToAnyPublisher())
    }

    @Test("처음 화면(헤더·불러오는 중 카드·댓글 입력)이 같다")
    func initial() throws {
        #expect(try hostedSnapshot(legacy()) == hostedSnapshot(new()))
    }

    @Test("통제: 불러오는 중이 아니면(본문 문구가 다르면) 픽셀이 다르다")
    func detectsBody() throws {
        #expect(try hostedSnapshot(legacy()) != hostedSnapshot(new(isLoading: false)))
    }
}
