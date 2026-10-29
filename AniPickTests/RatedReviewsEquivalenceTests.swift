//
//  RatedReviewsEquivalenceTests.swift
//  AniPickTests
//
//  이관한 평가한 작품 화면이 레거시와 같은 모양인지 픽셀로 비교한다 (R MyInfo 2).
//  레거시 화면은 보일 때 실제 서버에 첫 페이지를 요청한다. 응답은 스냅샷 뒤에 오므로 결과에는 영향이 없다.
//  정렬 메뉴를 연 상태는 비교할 수 없다 — 첫 레이아웃의 스크롤 위치 변경이 양쪽 모두 메뉴를 닫는다(통제 테스트로 확인).
//

import FeatureTestSupport
import MyInfoClientInterface
import MyInfoClientTesting
import Navigation
import ReviewClientTesting
import SwiftUI
import Testing

@testable import AniPick
@testable import MyInfoFeature

@MainActor
@Suite("평가한 작품 ↔ 레거시", .serialized)
struct RatedReviewsEquivalenceTests {
    struct Row: Sendable {
        let id: Int
        let content: String?
        let rating: Double
        let likes: Int?
    }

    private static let rows = [
        Row(id: 1, content: "짧은 리뷰", rating: 4.5, likes: 12),
        Row(id: 2, content: nil, rating: 3, likes: nil),
        Row(id: 3, content: String(repeating: "아주 긴 리뷰 내용입니다. ", count: 12), rating: 0.5, likes: 0),
    ]

    private func legacy(
        _ rows: [Row],
        total: Int?,
        sort: RatedSortOption = .latest,
        reviewOnly: Bool = false,
        sortMenu: Bool = false
    ) -> some View {
        let viewModel = RatedAnimeListViewModel(navigationManager: NavigationManager())
        viewModel.ratedReviewList = rows.map {
            MyReview(
                animeId: $0.id * 10, title: "애니 \($0.id)", coverImageUrl: nil, rating: $0.rating,
                reviewId: $0.id, reviewContent: $0.content, createdAt: "2026.10.0\($0.id)",
                likeCount: $0.likes, isLiked: false)
        }
        viewModel.totalCount = total
        viewModel.sortCategory = sort
        viewModel.isShowOnlyReview = reviewOnly
        viewModel.isShowSortOptionView = sortMenu
        return AniPick.RatedAnimeListView(viewModel: viewModel)
    }

    private func new(
        _ rows: [Row],
        total: Int?,
        sort: RatedSort = .latest,
        reviewOnly: Bool = false,
        sortMenu: Bool = false
    ) -> some View {
        var state = RatedReviewsReducer.State()
        state.reviews = rows.map {
            RatedReview(
                animeId: $0.id * 10, title: "애니 \($0.id)", coverImageUrl: nil, rating: $0.rating,
                reviewId: $0.id, reviewContent: $0.content, createdAt: "2026.10.0\($0.id)",
                likeCount: $0.likes)
        }
        state.totalCount = total
        state.sort = sort
        state.isReviewOnly = reviewOnly
        state.isSortMenuPresented = sortMenu
        let reducer = RatedReviewsReducer(
            myInfoClient: MockMyInfoClient(),
            reviewClient: MockReviewClient(),
            navigator: LegacyNavigator(navigationManager: NavigationManager())
        )
        return RatedReviewsView(state: state, reducer: reducer)
    }

    @Test("목록(긴 리뷰의 더보기, 내용·좋아요 없는 칸)이 같다")
    func list() throws {
        #expect(try hostedSnapshot(legacy(Self.rows, total: 3)) == hostedSnapshot(new(Self.rows, total: 3)))
    }

    @Test("리뷰만 보기 켬 + 평가 낮은 순 표시가 같다")
    func reviewOnlyAndSort() throws {
        #expect(
            try hostedSnapshot(legacy(Self.rows, total: 3, sort: .ratingAsc, reviewOnly: true))
                == hostedSnapshot(new(Self.rows, total: 3, sort: .ratingAsc, reviewOnly: true)))
    }

    @Test("빈 화면이 같다 (총 개수 없음 → 0개)")
    func empty() throws {
        #expect(try hostedSnapshot(legacy([], total: nil)) == hostedSnapshot(new([], total: nil)))
    }

    @Test("통제: 별점이 다르면 픽셀이 다르다")
    func detectsRating() throws {
        var changed = Self.rows
        changed[0] = Row(id: 1, content: "짧은 리뷰", rating: 4, likes: 12)

        #expect(try hostedSnapshot(legacy(Self.rows, total: 3)) != hostedSnapshot(new(changed, total: 3)))
    }
}
