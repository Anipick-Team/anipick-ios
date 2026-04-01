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

    let animeId: Int

    init(animeId: Int) {
        self.animeId = animeId
        // TODO: API 연결 시 fetchPosts() 호출
        self.posts = Self.dummyPosts
    }

    func fetchPosts() {
        // TODO: API 연결
    }

    private static let dummyPosts: [CommunityPost] = [
        CommunityPost(
            id: 1,
            authorName: "작성자 닉네임",
            authorImageUrl: nil,
            date: "2024.01.23",
            content: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다는. 다기프다 헤즈언아셔 나온쥿셍 즈나아...",
            imageUrls: [],
            likeCount: 0,
            dislikeCount: 0,
            commentCount: 0,
            isSpoiler: true
        ),
        CommunityPost(
            id: 2,
            authorName: "작성자 닉네임",
            authorImageUrl: nil,
            date: "2024.01.23",
            content: "한줄",
            imageUrls: [],
            likeCount: 0,
            dislikeCount: 0,
            commentCount: 0,
            isSpoiler: false
        ),
        CommunityPost(
            id: 3,
            authorName: "작성자 닉네임",
            authorImageUrl: nil,
            date: "2024.01.23",
            content: "사단타는 밤퍼노아 몽즌디를 염드의 브히가 등가 안티로 소다는. 다기프다 헤즈언아셔 나온쥿셍 즈나아...",
            imageUrls: ["", "", "", "", "", "", "", ""],
            likeCount: 0,
            dislikeCount: 0,
            commentCount: 0,
            isSpoiler: false
        )
    ]
}
