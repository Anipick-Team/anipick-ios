//
//  CommunityViewModel.swift
//  AniPick
//

import SwiftUI

enum CommunityFilter: String, CaseIterable {
    case all = "전체"
    case monthly = "월간"
    case weekly = "주간"
    case daily = "일간"
}

struct CommunityPost: Identifiable {
    let id: Int
    let authorName: String
    let authorImageUrl: String?
    let date: String
    let title: String
    let content: String
    let imageUrls: [String]
    /// 첨부 사진 전체 개수 (썸네일은 첫 번째 1장만 내려옴)
    let imageCount: Int
    let likeCount: Int
    let dislikeCount: Int
    let commentCount: Int
    let isSpoiler: Bool
}

final class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var selectedFilter: CommunityFilter = .all
    @Published var isShowSpoiler: Bool = true
    @Published var isLoading: Bool = false
    @Published var hasNextPage: Bool = true
    @Published var errorMessage: String?

    let seriesId: Int
    private var lastId: Int?
    private var lastValue: String?

    init(seriesId: Int) {
        self.seriesId = seriesId
        fetchPosts(reset: true)
    }

    func fetchPosts(reset: Bool = false) {
        guard !isLoading, reset || hasNextPage else { return }

        if reset {
            lastId = nil
            lastValue = nil
            hasNextPage = true
        }

        isLoading = true
        errorMessage = nil
        Task {
            do {
                let response = try await CommunityAPIService.shared.posts(
                    seriesId: seriesId,
                    sort: selectedFilter.apiValue,
                    lastValue: lastValue,
                    lastId: lastId
                )
                let newPosts = (response.result?.posts ?? []).map(Self.mapPost)
                let cursor = response.result?.cursor

                DLog("커뮤니티 게시글 조회 성공 - seriesId: \(seriesId), count: \(newPosts.count), cursor: \(String(describing: cursor))")
                await MainActor.run {
                    self.posts = reset ? newPosts : self.posts + newPosts
                    self.lastId = cursor?.lastId
                    self.lastValue = cursor?.lastValue
                    self.hasNextPage = newPosts.isEmpty == false && cursor?.lastId != nil
                    self.isLoading = false
                }
            } catch {
                DLog("커뮤니티 게시글 조회 실패 - seriesId: \(seriesId), error: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "게시글을 불러오지 못했습니다."
                }
            }
        }
    }

    private static func mapPost(_ post: CommunityPostDTO) -> CommunityPost {
        CommunityPost(
            id: post.postId,
            authorName: post.nickname ?? "익명",
            authorImageUrl: post.profileImageUrl,
            date: post.createdAt ?? "",
            title: post.title ?? "",
            content: post.content ?? "",
            imageUrls: (post.thumbnailImageId.map { ["\(NetworkManager.baseUrl)api/image/\($0)"] } ?? []),
            imageCount: post.imageCount ?? (post.thumbnailImageId == nil ? 0 : 1),
            likeCount: post.likeCount ?? 0,
            dislikeCount: 0,
            commentCount: post.commentCount ?? 0,
            isSpoiler: post.isSpoiler ?? false
        )
    }
}

private extension CommunityFilter {
    var apiValue: String {
        switch self {
        case .all: return "latest"
        case .monthly: return "popularMonthly"
        case .weekly: return "popularWeekly"
        case .daily: return "popularDaily"
        }
    }
}
