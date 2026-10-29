import ProjectDescription
import ProjectDescriptionHelpers

// 애니 상세와 상세에서 들어가는 화면. 아직 레거시인 화면은 App이 Route를 가로챈다 (같은 Feature 안의 Strangler)
let project = Project.feature(
    "Detail",
    dependencies: [.client("Detail"), .client("Community"), .feature("Explore")],
    modules: [.core("Analytics"), .core("MVICore"), .core("Navigation"), .shared("DesignSystem")],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore"), .core("Analytics")]
)
