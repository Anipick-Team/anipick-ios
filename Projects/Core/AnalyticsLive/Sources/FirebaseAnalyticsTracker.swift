import Analytics
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics

public enum AnalyticsLive {
    /// 앱 시작 시 1회. Firebase를 쓰는 어떤 호출보다 먼저 부른다.
    public static func configure() {
        FirebaseApp.configure()
    }
}

/// Firebase Analytics·Crashlytics로 보낸다.
///
/// 이 파일은 우리 `Analytics` 모듈과 `FirebaseAnalytics`를 함께 import하므로, 이름 `Analytics`가
/// Firebase 타입으로 해석된다. Firebase 쪽은 `FirebaseAnalytics.Analytics`로 한정해 쓴다.
public struct FirebaseAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func log(_ event: AnalyticsEvent) {
        FirebaseAnalytics.Analytics.logEvent(
            event.name,
            parameters: Self.firebaseParameters(event.parameters)
        )
    }

    public func recordNonFatal(_ error: any Error, breadcrumb: String) {
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.log(breadcrumb)
        crashlytics.record(error: error)
    }

    static func firebaseParameters(_ parameters: [String: AnalyticsValue]) -> [String: Any] {
        return parameters.mapValues { value -> Any in
            switch value {
            case .string(let string):
                return string
            case .int(let int):
                return int
            case .double(let double):
                return double
            }
        }
    }
}
