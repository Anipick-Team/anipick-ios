import ProjectDescription
import ProjectDescriptionHelpers

// Feature 테스트·Example이 함께 쓰는 가짜 (이관 B4: Setting 2~3개 화면 뒤 추출)
let project = Project.module(
    "FeatureTestSupport",
    layer: .shared,
    isolation: .mainActor,
    dependencies: [.core("Navigation"), .core("Analytics")],
    hasTests: false
)
