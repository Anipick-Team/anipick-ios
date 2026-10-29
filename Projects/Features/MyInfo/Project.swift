import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    "MyInfo",
    dependencies: [
        .client("MyInfo"), .client("Review"), .feature("Detail"), .feature("Review"),
        .feature("Explore"),
    ],
    modules: [.core("MVICore"), .core("Navigation"), .shared("DesignSystem")],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore")]
)
