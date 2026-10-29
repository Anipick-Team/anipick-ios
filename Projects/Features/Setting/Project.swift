import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    "Setting",
    dependencies: [.client("User"), .client("Auth")],
    modules: [.core("MVICore"), .core("Navigation"), .shared("DesignSystem")],
    testModules: [.shared("FeatureTestSupport")]
)
