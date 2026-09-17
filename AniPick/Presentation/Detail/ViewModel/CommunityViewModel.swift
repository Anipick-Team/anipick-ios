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

    let animeId: Int
    @Published private(set) var seriesId: Int?
    private var lastId: Int?
    private var lastValue: String?

    init(animeId: Int) {
        self.animeId = animeId
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
        Task {
            do {
                let resolvedSeriesId: Int
                do {
                    let board = try await CommunityAPIService.shared.boardByAnime(animeId: animeId)
                    if let seriesId = board.result?.seriesId {
                        resolvedSeriesId = seriesId
                    } else {
                        // 일부 응답에서는 애니 ID와 게시판의 series ID가 동일하게 사용됩니다.
                        resolvedSeriesId = animeId
                        DLog("커뮤니티 게시판 응답에 seriesId 없음 - animeId를 seriesId로 사용: \(animeId)")
                    }
                } catch {
                    // 게시판 조회가 실패해도 게시글 API를 직접 시도해 화면이 비지 않도록 합니다.
                    resolvedSeriesId = animeId
                    DLog("커뮤니티 게시판 조회 실패, animeId로 게시글 조회 재시도 - animeId: \(animeId), error: \(error)")
                }

                let response = try await CommunityAPIService.shared.posts(
                    seriesId: resolvedSeriesId,
                    sort: selectedFilter.apiValue,
                    lastValue: lastValue,
                    lastId: lastId
                )
                let newPosts = (response.result?.posts ?? []).map(Self.mapPost)
                let cursor = response.result?.cursor

                DLog("커뮤니티 게시글 조회 성공 - seriesId: \(resolvedSeriesId), count: \(newPosts.count), cursor: \(String(describing: cursor))")
                await MainActor.run {
                    self.seriesId = resolvedSeriesId
                    self.posts = reset ? newPosts : self.posts + newPosts
                    self.lastId = cursor?.lastId
                    self.lastValue = cursor?.lastValue
                    self.hasNextPage = newPosts.isEmpty == false && cursor?.lastId != nil
                    self.isLoading = false
                }
            } catch {
                DLog("커뮤니티 게시글 조회 실패 - animeId: \(animeId), error: \(error.localizedDescription)")
                await MainActor.run { self.isLoading = false }
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
