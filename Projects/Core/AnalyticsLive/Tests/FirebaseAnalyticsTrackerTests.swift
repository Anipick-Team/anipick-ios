import Analytics
import Testing

@testable import AnalyticsLive

/// Firebase를 호출하지 않는 변환만 시험한다 — `configure()` 없이 Crashlytics를 부르면 크래시한다.
@Suite("FirebaseAnalyticsTracker")
struct FirebaseAnalyticsTrackerTests {
    @Test("파라미터 값을 레거시와 같은 Swift 타입으로 바꾼다 (Int·Double·String)")
    func convertsParameters() {
        let converted = FirebaseAnalyticsTracker.firebaseParameters([
            "anime_id": .int(7),
            "rating": .double(4.5),
            "anime_title": .string("A"),
        ])

        #expect(converted.count == 3)
        #expect(converted["anime_id"] as? Int == 7)
        #expect(converted["rating"] as? Double == 4.5)
        #expect(converted["anime_title"] as? String == "A")
        // Int가 Double로 바뀌면 Firebase에 다른 타입으로 전송된다
        #expect(type(of: converted["anime_id"]!) == Int.self)
        #expect(type(of: converted["rating"]!) == Double.self)
    }
}
