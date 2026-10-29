//
//  RecentReviewsEquivalenceTests.swift
//  AniPickTests
//
//  이관한 최근 리뷰가 레거시와 같은 모양인지 픽셀로 비교한다 (R Home 3).
//  레거시는 만들 때 운영 서버에 최근 리뷰를 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//  프로필 주소를 비워 양쪽 모두 초록 원(받기 전 모양)으로 비교한다.
//

import Navigation
import ReviewClientInterface
import ReviewClientTesting
import SwiftUI
import Testing

@testable import AniPick
@testable import HomeFeature

@MainActor
@Suite("최근 리뷰 ↔ 레거시", .serialized)
struct RecentReviewsEquivalenceTests {
    struct Row: Sendable {
        var id: Int
        var rating: Double = 4.5
        var content: String? = "재밌어요"
        var reviewContent: String? = nil
        var likeCount: Int? = 3
        var liked: Bool? = false
    }

    private static let longText = String(repeating: "아주 길게 쓴 리뷰 내용입니다. ", count: 12)

    private func legacy(_ rows: [Row]) -> some View {
        let viewModel = RecentReviewViewModel(navigationManager: NavigationManager())
        viewModel.recentReviewList = rows.map {
            ReviewItem(
                reviewId: $0.id, userId: 1, animeId: 2, animeTitle: "애니 \($0.id)", animeCoverImageUrl: nil,
                rating: $0.rating, reviewContent: $0.reviewContent, nickname: "닉네임", profileImageUrl: nil,
                createdAt: "2026.10.30", likeCount: $0.likeCount, likedByCurrentUser: $0.liked, isMine: false,
                content: $0.content, isSpoiler: false)
        }
        return AniPick.RecentReviewView(viewModel: viewModel)
    }

    private func new(_ rows: [Row]) -> some View {
        var state = RecentReviewsReducer.State()
        state.didStart = true
        state.reviews = rows.map {
            RecentReview(
                reviewId: $0.id, userId: 1, animeId: 2, animeTitle: "애니 \($0.id)", animeCoverImageUrl: nil,
                rating: $0.rating, text: $0.content ?? $0.reviewContent ?? "--", nickname: "닉네임",
                profileImageId: nil, createdAt: "2026.10.30", likeCount: $0.likeCount, isLiked: $0.liked)
        }
        return HomeFeature.RecentReviewsView(
            state: state,
            reducer: RecentReviewsReducer(
                reviewClient: MockReviewClient(), navigator: LegacyNavigator(navigationManager: NavigationManager())),
            imageURL: { URL(string: "https://example.invalid/\($0)")! })
    }

    @Test("목록(내용·옛 내용·없음, 좋아요, 개수 없음, 긴 리뷰)이 같다")
    func list() throws {
        let rows = [
            Row(id: 1), Row(id: 2, rating: 3.5, content: nil, reviewContent: "옛 내용", likeCount: nil, liked: true),
            Row(id: 3, rating: 0, content: nil, reviewContent: nil), Row(id: 4, content: Self.longText),
        ]
        #expect(try hostedSnapshot(legacy(rows)) == hostedSnapshot(new(rows)))
    }

    @Test("빈 목록이 같다")
    func empty() throws {
        #expect(try hostedSnapshot(legacy([])) == hostedSnapshot(new([])))
    }

    @Test("통제: 좋아요 상태가 다르면 픽셀이 다르다")
    func detectsLike() throws {
        #expect(try hostedSnapshot(legacy([Row(id: 1, liked: true)])) != hostedSnapshot(new([Row(id: 1, liked: false)])))
    }
}
