//
//  AnimeReviewsEquivalenceTests.swift
//  AniPickTests
//
//  이관한 애니 상세 "리뷰" 탭이 레거시와 같은 모양인지 픽셀로 비교한다 (R Detail 5).
//  레거시 상세 화면의 탭은 private @State라 바꿀 수 없어, 리뷰 탭 화면(`ReviewDetailInfoView`)과 새 `AnimeReviewsTab`을
//  같은 틀(ScrollView, 좌우 10)에 넣어 비교한다. 레거시 탭은 보이고 0.2초 뒤 운영 서버에 요청한다. 스냅샷이 먼저다.
//

import ReviewClientInterface
import SwiftUI
import Testing

@testable import AniPick
@testable import DetailFeature

@MainActor
@Suite("애니 상세 리뷰 탭 ↔ 레거시", .serialized)
struct AnimeReviewsEquivalenceTests {
    struct Row: Sendable {
        var id: Int
        var rating = 4.5
        var text = "재밌어요"
        var likeCount: Int? = 3
        var liked = false
    }

    struct Setup: Sendable {
        var myReview = ""
        var stored = 0.0
        var rows = [Row(id: 1), Row(id: 2, rating: 2, text: String(repeating: "긴 리뷰 ", count: 30), likeCount: nil, liked: true)]
        var spoilers = false
        var sort = 0
        var sortMenu = false
    }

    private func legacy(_ setup: Setup) -> some View {
        let viewModel = AnimationInfoViewModel(animeId: 999_999, navigationManager: NavigationManager())
        viewModel.reviewContent = setup.myReview
        viewModel.storedMyReviewRate = setup.stored
        viewModel.myReviewCreatedAt = "2026.10.30"
        viewModel.myLikeCount = 5
        viewModel.reviewCount = setup.rows.count
        viewModel.isSpolier = setup.spoilers
        viewModel.selectedReviewSortOption = SortOption.allCases[setup.sort]
        viewModel.reviewList = setup.rows.map {
            ReviewItem(
                reviewId: $0.id, userId: 1, animeId: 1, animeTitle: nil, animeCoverImageUrl: nil, rating: $0.rating,
                reviewContent: nil, nickname: "닉네임", profileImageUrl: nil, createdAt: "2026.10.30",
                likeCount: $0.likeCount, likedByCurrentUser: $0.liked, isMine: false, content: $0.text, isSpoiler: false)
        }
        return ScrollView {
            AniPick.ReviewDetailInfoView(
                viewModel: viewModel, scrollOffset: .constant(0), isShowOnlyReview: .constant(false),
                isShowSortOptionView: .constant(setup.sortMenu), starRating: .constant(setup.stored),
                onReportButtonTapped: { _, _ in }, onMoreButtonTapped: { _, _, _ in }
            )
            .padding(.horizontal, 10)
        }
    }

    private func new(_ setup: Setup) -> some View {
        var state = AnimeDetailReducer.State(animeId: 999_999)
        state.myReviewContent = setup.myReview
        state.storedRating = setup.stored
        state.pendingRating = setup.stored
        state.myReviewCreatedAt = "2026.10.30"
        state.myLikeCount = 5
        state.reviewCount = setup.rows.count
        state.showsSpoilers = setup.spoilers
        state.reviewSort = AnimeDetailReducer.ReviewSort.allCases[setup.sort]
        state.isSortMenuPresented = setup.sortMenu
        state.reviews = setup.rows.map {
            RecentReview(
                reviewId: $0.id, userId: 1, animeId: 1, animeTitle: nil, animeCoverImageUrl: nil, rating: $0.rating,
                text: $0.text, nickname: "닉네임", profileImageId: nil, createdAt: "2026.10.30", likeCount: $0.likeCount,
                isLiked: $0.liked, isMine: false, isSpoiler: false)
        }
        return ScrollView {
            AnimeReviewsTab(state: state, imageURL: { URL(string: "https://example.invalid/\($0)")! }) { _ in }
                .padding(.horizontal, 10)
        }
    }

    @Test(
        "리뷰 탭(별점 상자·내 리뷰 카드·스포일러·정렬·정렬 메뉴·빈 목록)이 같다",
        arguments: [
            Setup(), Setup(stored: 3.5), Setup(myReview: "내가 쓴 리뷰", stored: 4, spoilers: true, sort: 2),
            Setup(sortMenu: true), Setup(rows: []),
        ])
    func tab(setup: Setup) throws {
        #expect(try hostedSnapshot(legacy(setup)) == hostedSnapshot(new(setup)))
    }

    @Test("통제: 내 별점이 다르면 픽셀이 다르다")
    func detectsRating() throws {
        #expect(try hostedSnapshot(legacy(Setup(stored: 3))) != hostedSnapshot(new(Setup(stored: 4))))
    }

    @Test("통제: 리뷰 좋아요 상태가 다르면 픽셀이 다르다")
    func detectsLike() throws {
        #expect(
            try hostedSnapshot(legacy(Setup(rows: [Row(id: 1, liked: true)])))
                != hostedSnapshot(new(Setup(rows: [Row(id: 1, liked: false)]))))
    }
}
