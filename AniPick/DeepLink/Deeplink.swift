//
//  Deeplink.swift
//  AniPick
//
//  Created by cho on 11/4/25.
//
import SwiftUI

enum DeepLink: Equatable {
    case anime(id: Int)
    case communityPost(id: Int)
    case producer(id: Int)
    case unknown
}

// MARK: - URL 경로 계약
// 공유 링크 생성(universalLink)과 수신 파싱(init(url:))은 같은 경로를 써야 한다. Android(DeepLinkParser.kt)와 동일.
//  - /app/anime/detail/{animeId}
//  - /app/community/post/{postId}
extension DeepLink {
    private static let universalLinkHost = "anipick.p-e.kr"

    /// Universal Link(https://anipick.p-e.kr/app/...)와 커스텀 스킴(anipick://...)을 DeepLink로 변환한다.
    init(url: URL) {
        let components = url.pathComponents.filter { $0 != "/" }

        // Universal Link: https://anipick.p-e.kr/app/...
        if url.scheme == "https", url.host == Self.universalLinkHost {
            guard components.first == "app" else {
                self = .unknown
                return
            }
            self = Self.parseAppPath(Array(components.dropFirst()))
            return
        }

        // Custom scheme
        switch url.host {
        case "anime":
            // anipick://anime/123
            if let idStr = components.first, let id = Int(idStr) {
                self = .anime(id: id)
            } else {
                self = .unknown
            }
        case "app":
            // anipick://app/anime/detail/123, anipick://app/community/post/123
            self = Self.parseAppPath(components)
        case "producer":
            if let idStr = components.first, let id = Int(idStr) {
                self = .producer(id: id)
            } else {
                self = .unknown
            }
        default:
            self = .unknown
        }
    }

    /// 공유용 Universal Link. 앱이 없으면 웹 랜딩으로 열린다.
    var universalLink: URL? {
        switch self {
        case .anime(let id):
            return URL(string: "https://\(Self.universalLinkHost)/app/anime/detail/\(id)")
        case .communityPost(let id):
            return URL(string: "https://\(Self.universalLinkHost)/app/community/post/\(id)")
        case .producer, .unknown:
            return nil
        }
    }

    /// `/app` 이후 경로를 해석한다.
    private static func parseAppPath(_ components: [String]) -> DeepLink {
        guard components.count >= 3, let id = Int(components[2]) else { return .unknown }

        switch (components[0], components[1]) {
        case ("anime", "detail"):
            return .anime(id: id)
        case ("community", "post"):
            return .communityPost(id: id)
        default:
            return .unknown
        }
    }
}
