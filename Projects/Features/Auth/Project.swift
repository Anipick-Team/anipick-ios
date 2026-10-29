import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    "Auth",
    dependencies: [.client("Auth")],
    modules: [
        .core("MVICore"), .core("Navigation"), .core("Analytics"), .shared("DesignSystem"),
    ],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore")]
)
