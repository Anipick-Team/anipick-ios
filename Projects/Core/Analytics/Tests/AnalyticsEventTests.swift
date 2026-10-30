import Testing

@testable import Analytics

/// 레거시 `AnalyticsManager`와 같은 이름·키·값 타입인지 (이관 R14).
/// Firebase 상수 값은 Firebase 12.16.0 `FIREventNames.h`·`FIRParameterNames.h`에서 확인했다.
@Suite("AnalyticsEvent 목록")
struct AnalyticsEventTests {
    @Test("애니 상세·좋아요·좋아요 취소: anime_id(Int), anime_title(String, nil이면 빈 문자열)")
    func animeEvents() {
        let expected: [String: AnalyticsValue] = ["anime_id": .int(7), "anime_title": .string("A")]
        let untitled: [String: AnalyticsValue] = ["anime_id": .int(7), "anime_title": .string("")]

        #expect(
            AnalyticsEvent.animeDetailView(animeId: 7, animeTitle: "A")
                == .init(name: "anime_detail_view", parameters: expected))
        #expect(
            AnalyticsEvent.animeLike(animeId: 7, animeTitle: "A")
                == .init(name: "anime_like", parameters: expected))
        #expect(
            AnalyticsEvent.animeUnlike(animeId: 7, animeTitle: nil)
                == .init(name: "anime_unlike", parameters: untitled))
    }

    @Test("공유: Firebase share 이벤트, item_id는 문자열")
    func shareEvent() {
        #expect(
            AnalyticsEvent.animeShare(animeId: 7, animeTitle: nil)
                == .init(
                    name: "share",
                    parameters: [
                        "item_id": .string("7"),
                        "item_name": .string(""),
                        "content_type": .string("anime"),
                    ]
                )
        )
    }

    @Test("리뷰 작성: rating은 Double, is_spoiler는 Int 1·0", arguments: [(true, 1), (false, 0)])
    func reviewWriteEvent(isSpoiler: Bool, flag: Int) {
        #expect(
            AnalyticsEvent.reviewWrite(animeId: 7, rating: 4.5, isSpoiler: isSpoiler)
                == .init(
                    name: "review_write",
                    parameters: [
                        "anime_id": .int(7), "rating": .double(4.5), "is_spoiler": .int(flag),
                    ]
                )
        )
    }

    @Test("검색·로그인·가입: Firebase 권장 이벤트와 파라미터 이름")
    func recommendedEvents() {
        #expect(
            AnalyticsEvent.search(query: "q")
                == .init(name: "search", parameters: ["search_term": .string("q")]))
        #expect(
            AnalyticsEvent.login(method: "kakao")
                == .init(name: "login", parameters: ["method": .string("kakao")]))
        #expect(
            AnalyticsEvent.signUp
                == .init(name: "sign_up", parameters: ["method": .string("email")]))
    }

    @Test("오류 이벤트")
    func errorEvents() {
        #expect(
            AnalyticsEvent.apiError(context: "c", message: "m")
                == .init(
                    name: "api_error",
                    parameters: ["context": .string("c"), "message": .string("m")])
        )
        #expect(
            AnalyticsEvent.loginIssue(provider: "p", reason: "r")
                == .init(
                    name: "login_issue",
                    parameters: ["provider": .string("p"), "reason": .string("r")])
        )
    }

    @Test("화면 조회·온보딩: screen_view는 Firebase 권장 파라미터 이름을 쓴다")
    func screenAndOnboardingEvents() {
        #expect(
            AnalyticsEvent.screenView(name: "home")
                == .init(
                    name: "screen_view",
                    parameters: ["screen_name": .string("home"), "screen_class": .string("home")])
        )
        #expect(
            AnalyticsEvent.onboardingComplete(ratedCount: 3)
                == .init(name: "onboarding_complete", parameters: ["rated_count": .int(3)]))
    }
}
