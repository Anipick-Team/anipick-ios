import ProjectDescription
import ProjectDescriptionHelpers

// 홈 탭과 홈에서 들어가는 목록·검색. 화면을 이관하는 대로 Route를 늘린다
let project = Project.feature(
    "Home",
    dependencies: [.client("Home"), .feature("Detail")],
    modules: [.core("MVICore"), .core("Navigation"), .shared("DesignSystem")],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore")]
)
