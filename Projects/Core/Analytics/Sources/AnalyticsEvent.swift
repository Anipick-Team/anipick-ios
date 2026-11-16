public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
}

/// 분석 이벤트. 이름과 파라미터 키는 아래 목록에서만 정한다 — 레거시와 같아야 한다 (이관 R14).
public struct AnalyticsEvent: Sendable, Equatable {
    public let name: String
    public let parameters: [String: AnalyticsValue]

    public init(name: String, parameters: [String: AnalyticsValue]) {
        self.name = name
        self.parameters = parameters
    }
}

// MARK: - 이벤트 목록 (레거시 AniPick/Utils/AnalyticsManager.swift)

extension AnalyticsEvent {
    // MARK: 화면·온보딩

    /// Firebase 권장 이벤트 `screen_view` (`AnalyticsEventScreenView`)
    public static func screenView(name: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "screen_view",
            parameters: ["screen_name": .string(name), "screen_class": .string(name)]
        )
    }

    public static func onboardingComplete(ratedCount: Int) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "onboarding_complete",
            parameters: ["rated_count": .int(ratedCount)]
        )
    }

    // MARK: 애니 상세

    public static func animeDetailView(animeId: Int, animeTitle: String?) -> AnalyticsEvent {
        return anime("anime_detail_view", animeId: animeId, animeTitle: animeTitle)
    }

    public static func animeLike(animeId: Int, animeTitle: String?) -> AnalyticsEvent {
        return anime("anime_like", animeId: animeId, animeTitle: animeTitle)
    }

    public static func animeUnlike(animeId: Int, animeTitle: String?) -> AnalyticsEvent {
        return anime("anime_unlike", animeId: animeId, animeTitle: animeTitle)
    }

    /// Firebase 권장 이벤트 `share` (`AnalyticsEventShare`)
    public static func animeShare(animeId: Int, animeTitle: String?) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "share",
            parameters: [
                "item_id": .string("\(animeId)"),
                "item_name": .string(animeTitle ?? ""),
                "content_type": .string("anime"),
            ]
        )
    }

    // MARK: 리뷰

    public static func reviewWrite(
        animeId: Int,
        rating: Double,
        isSpoiler: Bool
    ) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "review_write",
            parameters: [
                "anime_id": .int(animeId),
                "rating": .double(rating),
                "is_spoiler": .int(isSpoiler ? 1 : 0),
            ]
        )
    }

    // MARK: 검색·로그인 (Firebase 권장 이벤트)

    public static func search(query: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "search", parameters: ["search_term": .string(query)])
    }

    public static func login(method: String) -> AnalyticsEvent {
        return AnalyticsEvent(name: "login", parameters: ["method": .string(method)])
    }

    public static let signUp = AnalyticsEvent(
        name: "sign_up",
        parameters: ["method": .string("email")]
    )

    // MARK: 오류

    public static func apiError(context: String, message: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "api_error",
            parameters: ["context": .string(context), "message": .string(message)]
        )
    }

    public static func loginIssue(provider: String, reason: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "login_issue",
            parameters: ["provider": .string(provider), "reason": .string(reason)]
        )
    }

    private static func anime(_ name: String, animeId: Int, animeTitle: String?) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: name,
            parameters: ["anime_id": .int(animeId), "anime_title": .string(animeTitle ?? "")]
        )
    }
}
