import ProjectDescription
import ProjectDescriptionHelpers

// Firebase는 이 모듈만 의존한다. App이 Firebase를 직접 의존하면 정적 라이브러리가 두 벌 링크된다.
// 정적 framework인 이유: 동적이면 Firebase와 GoogleSignIn(App)이 함께 쓰는 정적 라이브러리
// (GoogleUtilities, FBLPromises 등)가 앱과 이 framework에 한 벌씩 들어간다.
let project = Project.module(
    "AnalyticsLive",
    layer: .core,
    isolation: .nonisolated,
    dependencies: [
        .core("Analytics"),
        .external("FirebaseCore"),
        .external("FirebaseAnalytics"),
        .external("FirebaseCrashlytics"),
        // 코드에서 쓰지 않는다. 링크만 하면 FirebaseApp.configure()가 성능 수집을 시작한다
        .external("FirebasePerformance"),
    ],
    product: .staticFramework
)
