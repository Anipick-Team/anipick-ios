import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    "Review",
    dependencies: [.client("Review")],
    modules: [
        .core("MVICore"), .core("Navigation"), .core("Analytics"), .shared("DesignSystem"),
    ],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore")]
)
