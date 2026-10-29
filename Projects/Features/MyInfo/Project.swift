import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    "MyInfo",
    dependencies: [
        .client("MyInfo"), .client("Review"), .feature("Detail"), .feature("Review"),
        .feature("Explore"),
        .feature("Setting"),
    ],
    modules: [.core("MVICore"), .core("Navigation"), .shared("DesignSystem")],
    testModules: [.shared("FeatureTestSupport"), .core("ClientCore")]
)
