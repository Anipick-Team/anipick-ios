import ProjectDescription
import ProjectDescriptionHelpers

// 탐색 탭과 커뮤니티 (이관 Q6: 커뮤니티는 이 모듈에 둔다)
let project = Project.feature(
    "Explore",
    dependencies: [.client("Community")],
    modules: [.core("MVICore"), .core("Navigation"), .shared("DesignSystem")],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore")]
)
